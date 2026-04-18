import sys
import types


def _raise_toml_load_error(*args, **kwargs):
    raise RuntimeError("skip external logging config in unit test")


sys.modules.setdefault("toml", types.SimpleNamespace(load=_raise_toml_load_error))

from tradingagents.dataflows.data_source_manager import ChinaDataSource, DataSourceManager
from tradingagents.dataflows import interface as interface_mod


def test_get_stock_data_does_not_return_tuple_when_fallback_fails(monkeypatch):
    manager = DataSourceManager.__new__(DataSourceManager)
    manager.current_source = ChinaDataSource.MONGODB
    manager.available_sources = [ChinaDataSource.AKSHARE]

    monkeypatch.setattr(
        manager,
        "_get_mongodb_data",
        lambda symbol, start_date, end_date, period="daily": ("❌ 原始数据质量异常", "mongodb"),
    )
    monkeypatch.setattr(
        manager,
        "_try_fallback_sources",
        lambda symbol, start_date, end_date, period="daily": (f"❌ 所有数据源都无法获取{symbol}的{period}数据", None),
    )

    result = DataSourceManager.get_stock_data(manager, "603986", "2025-04-18", "2026-04-18")

    assert isinstance(result, str)
    assert "原始数据质量异常" in result


def test_interface_unwraps_legacy_tuple_results(monkeypatch):
    monkeypatch.setattr(
        "tradingagents.dataflows.data_source_manager.get_china_stock_data_unified",
        lambda ticker, start_date, end_date: ("header\n2025-04-18 603986", "akshare"),
    )

    result = interface_mod.get_china_stock_data_unified("603986", "2025-04-18", "2026-04-18")

    assert isinstance(result, str)
    assert "603986" in result
