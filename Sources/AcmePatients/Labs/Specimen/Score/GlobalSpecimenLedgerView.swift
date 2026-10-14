import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a global specimen ledger.
    final class GlobalSpecimenLedgerView {
        var code: String
        var titleText: String
        var floorValue: String
        var label: String
        var capacity: String
        var windowDays: String
        var statusLabel: String

        init(code: String, titleText: String, floorValue: String, label: String, capacity: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.floorValue = floorValue
            self.label = label
            self.capacity = capacity
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalSpecimenLedgerView(_ item: GlobalSpecimenLedger) -> GlobalSpecimenLedgerView {
        return GlobalSpecimenLedgerView(
            code: item.code,
            titleText: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            label: Kit.Text.truncate(item.label, limit: 64),
            capacity: String(item.capacity),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalSpecimenLedgerViews(_ items: [GlobalSpecimenLedger]) -> [GlobalSpecimenLedgerView] {
        var views: [GlobalSpecimenLedgerView] = []
        for item in items {
            views.append(toGlobalSpecimenLedgerView(item))
        }
        return views
    }

    static func sumGlobalSpecimenLedgerView(_ view: GlobalSpecimenLedgerView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedFloorValue + Double(parsedCapacity) + Double(parsedWindowDays)
    }
}
