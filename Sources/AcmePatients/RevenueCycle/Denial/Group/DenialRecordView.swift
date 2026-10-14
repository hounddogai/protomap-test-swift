import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial record.
    final class DenialRecordView {
        var codeText: String
        var nameText: String
        var windowDays: String
        var amount: String
        var label: String
        var ratio: String
        var minimum: String
        var wardText: String
        var facility: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, nameText: String, windowDays: String, amount: String, label: String, ratio: String, minimum: String, wardText: String, facility: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.windowDays = windowDays
            self.amount = amount
            self.label = label
            self.ratio = ratio
            self.minimum = minimum
            self.wardText = wardText
            self.facility = facility
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toDenialRecordView(_ item: DenialRecord) -> DenialRecordView {
        return DenialRecordView(
            codeText: item.code,
            nameText: item.name,
            windowDays: String(item.windowDays),
            amount: String(format: "%.2f", item.amount),
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            minimum: String(format: "%.2f", item.minimum),
            wardText: item.ward,
            facility: item.facility,
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialRecordViews(_ items: [DenialRecord]) -> [DenialRecordView] {
        var views: [DenialRecordView] = []
        for item in items {
            views.append(toDenialRecordView(item))
        }
        return views
    }

    static func sumDenialRecordView(_ view: DenialRecordView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedWindowDays) + parsedAmount + parsedRatio
    }
}
