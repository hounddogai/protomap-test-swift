import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a regional reference range slot.
    final class RegionalReferenceRangeSlotView {
        var code: String
        var nameText: String
        var batchSize: String
        var acuity: String
        var attemptsText: String
        var statusLabel: String

        init(code: String, nameText: String, batchSize: String, acuity: String, attemptsText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.batchSize = batchSize
            self.acuity = acuity
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalReferenceRangeSlotView(_ item: RegionalReferenceRangeSlot) -> RegionalReferenceRangeSlotView {
        return RegionalReferenceRangeSlotView(
            code: item.code,
            nameText: item.name,
            batchSize: String(item.batchSize),
            acuity: String(item.acuity),
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalReferenceRangeSlotViews(_ items: [RegionalReferenceRangeSlot]) -> [RegionalReferenceRangeSlotView] {
        var views: [RegionalReferenceRangeSlotView] = []
        for item in items {
            views.append(toRegionalReferenceRangeSlotView(item))
        }
        return views
    }

    static func sumRegionalReferenceRangeSlotView(_ view: RegionalReferenceRangeSlotView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedAcuity) + Double(parsedAttempts)
    }
}
