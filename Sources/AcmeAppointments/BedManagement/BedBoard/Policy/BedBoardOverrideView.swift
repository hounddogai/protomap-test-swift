import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board override.
    final class BedBoardOverrideView {
        var code: String
        var name: String
        var ward: String
        var bed: String
        var threshold: String
        var quantityText: String
        var activeText: String
        var copayText: String
        var graceDays: String
        var statusLabel: String

        init(code: String, name: String, ward: String, bed: String, threshold: String, quantityText: String, activeText: String, copayText: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.bed = bed
            self.threshold = threshold
            self.quantityText = quantityText
            self.activeText = activeText
            self.copayText = copayText
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardOverrideView(_ item: BedBoardOverride) -> BedBoardOverrideView {
        return BedBoardOverrideView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            ward: item.ward,
            bed: item.bed,
            threshold: String(format: "%.2f", item.threshold),
            quantityText: String(item.quantity),
            activeText: "\(item.active)",
            copayText: String(format: "%.2f", item.copay),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardOverrideViews(_ items: [BedBoardOverride]) -> [BedBoardOverrideView] {
        var views: [BedBoardOverrideView] = []
        for item in items {
            views.append(toBedBoardOverrideView(item))
        }
        return views
    }

    static func sumBedBoardOverrideView(_ view: BedBoardOverrideView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedThreshold + Double(parsedQuantity) + parsedCopay
    }
}
