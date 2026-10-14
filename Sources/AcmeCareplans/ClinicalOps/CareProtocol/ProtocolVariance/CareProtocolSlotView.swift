import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a care protocol slot.
    final class CareProtocolSlotView {
        var code: String
        var title: String
        var score: String
        var dosageMg: String
        var windowDays: String
        var costText: String
        var version: String
        var externalRef: String
        var statusLabel: String

        init(code: String, title: String, score: String, dosageMg: String, windowDays: String, costText: String, version: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.score = score
            self.dosageMg = dosageMg
            self.windowDays = windowDays
            self.costText = costText
            self.version = version
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolSlotView(_ item: CareProtocolSlot) -> CareProtocolSlotView {
        return CareProtocolSlotView(
            code: item.code,
            title: item.title,
            score: String(format: "%.2f", item.score),
            dosageMg: String(format: "%.2f", item.dosageMg),
            windowDays: String(item.windowDays),
            costText: String(format: "%.2f", item.cost),
            version: String(item.version),
            externalRef: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolSlotViews(_ items: [CareProtocolSlot]) -> [CareProtocolSlotView] {
        var views: [CareProtocolSlotView] = []
        for item in items {
            views.append(toCareProtocolSlotView(item))
        }
        return views
    }

    static func sumCareProtocolSlotView(_ view: CareProtocolSlotView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedScore + parsedDosageMg + Double(parsedWindowDays)
    }
}
