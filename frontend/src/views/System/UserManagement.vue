<template>
  <div class="user-management">
    <div class="page-header">
      <div>
        <h1 class="page-title">
          <el-icon><UserFilled /></el-icon>
          用户管理
        </h1>
        <p class="page-description">
          管理普通用户账号、启用状态和密码重置
        </p>
      </div>
      <div class="page-actions">
        <el-button @click="loadUsers" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button type="primary" @click="openCreateDialog">
          <el-icon><Plus /></el-icon>
          新增用户
        </el-button>
      </div>
    </div>

    <el-row :gutter="20" class="summary-row">
      <el-col :span="8">
        <el-card shadow="never" class="summary-card">
          <div class="summary-value">{{ totalUsers }}</div>
          <div class="summary-label">用户总数</div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="summary-card">
          <div class="summary-value">{{ activeUsers }}</div>
          <div class="summary-label">启用中</div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="summary-card">
          <div class="summary-value">{{ adminUsers }}</div>
          <div class="summary-label">管理员</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never">
      <template #header>
        <div class="table-header">
          <span>账号列表</span>
          <el-tag type="info">{{ totalUsers }} 个账号</el-tag>
        </div>
      </template>

      <el-table :data="users" v-loading="loading" style="width: 100%">
        <el-table-column prop="username" label="用户名" min-width="140" />
        <el-table-column prop="email" label="邮箱" min-width="220" />
        <el-table-column label="角色" width="120">
          <template #default="{ row }">
            <el-tag :type="row.is_admin ? 'danger' : 'info'">
              {{ row.is_admin ? '管理员' : '普通用户' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="110">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'warning'">
              {{ row.is_active ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="创建时间" width="190">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="最近登录" width="190">
          <template #default="{ row }">
            {{ formatDateTime(row.last_login) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="220" fixed="right">
          <template #default="{ row }">
            <div class="actions">
              <el-button link type="primary" @click="openResetPasswordDialog(row)">
                重置密码
              </el-button>
              <el-button
                v-if="row.is_active"
                link
                type="warning"
                :disabled="row.username === authStore.user?.username"
                @click="toggleUserStatus(row, false)"
              >
                禁用
              </el-button>
              <el-button
                v-else
                link
                type="success"
                @click="toggleUserStatus(row, true)"
              >
                启用
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog
      v-model="createDialogVisible"
      title="新增用户"
      width="520px"
      @closed="resetCreateForm"
    >
      <el-form
        ref="createFormRef"
        :model="createUserForm"
        :rules="createFormRules"
        label-width="100px"
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="createUserForm.username" placeholder="至少 3 位" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="createUserForm.email" placeholder="user@example.com" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input
            v-model="createUserForm.password"
            type="password"
            show-password
            placeholder="至少 6 位"
          />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input
            v-model="createUserForm.confirmPassword"
            type="password"
            show-password
            placeholder="再次输入密码"
          />
        </el-form-item>
        <el-form-item label="账号角色">
          <el-switch
            v-model="createUserForm.is_admin"
            inline-prompt
            active-text="管理员"
            inactive-text="普通"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="createDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitCreateUser">
          创建账号
        </el-button>
      </template>
    </el-dialog>

    <el-dialog
      v-model="resetPasswordDialogVisible"
      :title="`重置密码 · ${resetPasswordForm.username}`"
      width="460px"
      @closed="resetPasswordFormState"
    >
      <el-form
        ref="resetPasswordFormRef"
        :model="resetPasswordForm"
        :rules="resetPasswordRules"
        label-width="100px"
      >
        <el-form-item label="新密码" prop="new_password">
          <el-input
            v-model="resetPasswordForm.new_password"
            type="password"
            show-password
            placeholder="输入新密码"
          />
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input
            v-model="resetPasswordForm.confirmPassword"
            type="password"
            show-password
            placeholder="再次输入新密码"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="resetPasswordDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitResetPassword">
          重置密码
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { Plus, Refresh, UserFilled } from '@element-plus/icons-vue'
import { authApi } from '@/api/auth'
import { useAuthStore } from '@/stores/auth'
import type { AdminUser } from '@/types/auth'

interface CreateUserDialogForm {
  username: string
  email: string
  password: string
  confirmPassword: string
  is_admin: boolean
}

interface ResetPasswordDialogForm {
  username: string
  new_password: string
  confirmPassword: string
}

const authStore = useAuthStore()

const loading = ref(false)
const submitting = ref(false)
const users = ref<AdminUser[]>([])

const createDialogVisible = ref(false)
const resetPasswordDialogVisible = ref(false)
const createFormRef = ref<FormInstance>()
const resetPasswordFormRef = ref<FormInstance>()

const createUserForm = reactive<CreateUserDialogForm>({
  username: '',
  email: '',
  password: '',
  confirmPassword: '',
  is_admin: false
})

const resetPasswordForm = reactive<ResetPasswordDialogForm>({
  username: '',
  new_password: '',
  confirmPassword: ''
})

const totalUsers = computed(() => users.value.length)
const activeUsers = computed(() => users.value.filter((user) => user.is_active).length)
const adminUsers = computed(() => users.value.filter((user) => user.is_admin).length)

const validateCreateConfirmPassword = (_rule: unknown, value: string, callback: (error?: Error) => void) => {
  if (!value) {
    callback(new Error('请再次输入密码'))
    return
  }

  if (value !== createUserForm.password) {
    callback(new Error('两次输入的密码不一致'))
    return
  }

  callback()
}

const validateResetConfirmPassword = (_rule: unknown, value: string, callback: (error?: Error) => void) => {
  if (!value) {
    callback(new Error('请再次输入新密码'))
    return
  }

  if (value !== resetPasswordForm.new_password) {
    callback(new Error('两次输入的密码不一致'))
    return
  }

  callback()
}

const createFormRules: FormRules<CreateUserDialogForm> = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, message: '用户名至少 3 位', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '邮箱格式不正确', trigger: ['blur', 'change'] }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少 6 位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    { validator: validateCreateConfirmPassword, trigger: ['blur', 'change'] }
  ]
}

const resetPasswordRules: FormRules<ResetPasswordDialogForm> = {
  new_password: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码至少 6 位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    { validator: validateResetConfirmPassword, trigger: ['blur', 'change'] }
  ]
}

const formatDateTime = (value?: string) => {
  if (!value) {
    return '-'
  }

  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }

  return date.toLocaleString('zh-CN', {
    hour12: false
  })
}

const loadUsers = async () => {
  try {
    loading.value = true
    const response = await authApi.listUsers()
    if (response.success) {
      users.value = response.data.users
    }
  } catch (error: any) {
    console.error('加载用户列表失败:', error)
    ElMessage.error(error.message || '加载用户列表失败')
  } finally {
    loading.value = false
  }
}

const resetCreateForm = () => {
  createFormRef.value?.resetFields()
  createUserForm.is_admin = false
}

const resetPasswordFormState = () => {
  resetPasswordFormRef.value?.resetFields()
  resetPasswordForm.username = ''
}

const openCreateDialog = () => {
  createDialogVisible.value = true
}

const openResetPasswordDialog = (user: AdminUser) => {
  resetPasswordForm.username = user.username
  resetPasswordDialogVisible.value = true
}

const submitCreateUser = async () => {
  const valid = await createFormRef.value?.validate().catch(() => false)
  if (!valid) {
    return
  }

  try {
    submitting.value = true
    const response = await authApi.createUser({
      username: createUserForm.username,
      email: createUserForm.email,
      password: createUserForm.password,
      is_admin: createUserForm.is_admin
    })

    if (response.success) {
      ElMessage.success(response.message || '用户创建成功')
      createDialogVisible.value = false
      await loadUsers()
    }
  } catch (error: any) {
    console.error('创建用户失败:', error)
    ElMessage.error(error.message || '创建用户失败')
  } finally {
    submitting.value = false
  }
}

const submitResetPassword = async () => {
  const valid = await resetPasswordFormRef.value?.validate().catch(() => false)
  if (!valid) {
    return
  }

  try {
    submitting.value = true
    const response = await authApi.adminResetPassword({
      username: resetPasswordForm.username,
      new_password: resetPasswordForm.new_password
    })

    if (response.success) {
      ElMessage.success(response.message || '密码重置成功')
      resetPasswordDialogVisible.value = false
    }
  } catch (error: any) {
    console.error('重置密码失败:', error)
    ElMessage.error(error.message || '重置密码失败')
  } finally {
    submitting.value = false
  }
}

const toggleUserStatus = async (user: AdminUser, activate: boolean) => {
  const actionText = activate ? '启用' : '禁用'

  try {
    await ElMessageBox.confirm(
      `确定要${actionText}用户 ${user.username} 吗？`,
      `确认${actionText}`,
      {
        type: activate ? 'success' : 'warning'
      }
    )

    if (activate) {
      await authApi.activateUser(user.username)
    } else {
      await authApi.deactivateUser(user.username)
    }

    ElMessage.success(`用户已${actionText}`)
    await loadUsers()
  } catch (error: any) {
    if (error === 'cancel' || error === 'close' || error?.message === 'cancel') {
      return
    }

    console.error(`${actionText}用户失败:`, error)
    ElMessage.error(error.message || `${actionText}用户失败`)
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped lang="scss">
.user-management {
  padding: 24px;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 24px;
}

.page-title {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0 0 8px;
  font-size: 28px;
  font-weight: 700;
  color: #1f2937;
}

.page-description {
  margin: 0;
  color: #6b7280;
  font-size: 14px;
}

.page-actions {
  display: flex;
  gap: 12px;
}

.summary-row {
  margin-bottom: 20px;
}

.summary-card {
  text-align: center;
}

.summary-value {
  font-size: 28px;
  font-weight: 700;
  color: #111827;
}

.summary-label {
  margin-top: 8px;
  color: #6b7280;
  font-size: 13px;
}

.table-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.actions {
  display: flex;
  align-items: center;
  gap: 4px;
}

@media (max-width: 900px) {
  .user-management {
    padding: 16px;
  }

  .page-header {
    flex-direction: column;
  }

  .page-actions {
    width: 100%;
  }
}
</style>
