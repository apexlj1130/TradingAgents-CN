import { ApiClient } from './request'
import type { 
  LoginForm, 
  RegisterForm, 
  LoginResponse, 
  RefreshTokenResponse,
  User,
  ChangePasswordForm,
  CreateUserForm,
  AdminResetPasswordForm,
  UserListResponse
} from '@/types/auth'

export const authApi = {
  // 登录
  login: (data: LoginForm) =>
    ApiClient.post<LoginResponse>('/api/auth/login', data, {
      skipAuth: true,  // 登录请求不需要认证
      skipAuthError: true  // 跳过 401 错误的自动处理
    }),

  // 注册
  register: (data: RegisterForm) =>
    ApiClient.post('/api/auth/register', data, {
      skipAuth: true,  // 注册请求不需要认证
      skipAuthError: true  // 跳过 401 错误的自动处理
    }),

  // 登出
  logout: () =>
    ApiClient.post('/api/auth/logout'),

  // 刷新Token
  refreshToken: (refreshToken: string) =>
    ApiClient.post<RefreshTokenResponse>('/api/auth/refresh', { refresh_token: refreshToken }),

  // 获取用户信息
  getUserInfo: () =>
    ApiClient.get<User>('/api/auth/me'),

  // 获取用户权限（开源版不需要，admin拥有所有权限）
  // getUserPermissions: () =>
  //   ApiClient.get<UserPermissions>('/api/auth/permissions'),

  // 更新用户信息
  updateUserInfo: (data: Partial<User>) =>
    ApiClient.put<User>('/api/auth/me', data),

  // 修改密码
  changePassword: (data: ChangePasswordForm) =>
    ApiClient.post('/api/auth/change-password', data),

  // 重置密码
  resetPassword: (email: string) =>
    ApiClient.post('/api/auth/reset-password', { email }),

  // 管理员：获取用户列表
  listUsers: () =>
    ApiClient.get<UserListResponse>('/api/auth/users'),

  // 管理员：创建用户
  createUser: (data: CreateUserForm) =>
    ApiClient.post('/api/auth/create-user', data),

  // 管理员：重置密码
  adminResetPassword: (data: AdminResetPasswordForm) =>
    ApiClient.post('/api/auth/reset-password', data),

  // 管理员：启用用户
  activateUser: (username: string) =>
    ApiClient.post(`/api/auth/users/${encodeURIComponent(username)}/activate`),

  // 管理员：禁用用户
  deactivateUser: (username: string) =>
    ApiClient.post(`/api/auth/users/${encodeURIComponent(username)}/deactivate`),

  // 验证邮箱
  verifyEmail: (token: string) =>
    ApiClient.post('/api/auth/verify-email', { token })
}
