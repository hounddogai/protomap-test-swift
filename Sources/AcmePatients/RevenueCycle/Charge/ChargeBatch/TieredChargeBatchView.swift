import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a tiered charge batch.
    final class TieredChargeBatchView {
        var code: String
        var label: String
        var refills: String
        var priorityText: String
        var currency: String
        var diagnosisCode: String
        var sequence: String
        var limit: String
        var windowDays: String
        var bedText: String
        var statusLabel: String

        init(code: String, label: String, refills: String, priorityText: String, currency: String, diagnosisCode: String, sequence: String, limit: String, windowDays: String, bedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.refills = refills
            self.priorityText = priorityText
            self.currency = currency
            self.diagnosisCode = diagnosisCode
            self.sequence = sequence
            self.limit = limit
            self.windowDays = windowDays
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredChargeBatchView(_ item: TieredChargeBatch) -> TieredChargeBatchView {
        return TieredChargeBatchView(
            code: item.code,
            label: item.label,
            refills: String(item.refills),
            priorityText: String(item.priority),
            currency: item.currency,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            sequence: String(item.sequence),
            limit: String(item.limit),
            windowDays: String(item.windowDays),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredChargeBatchViews(_ items: [TieredChargeBatch]) -> [TieredChargeBatchView] {
        var views: [TieredChargeBatchView] = []
        for item in items {
            views.append(toTieredChargeBatchView(item))
        }
        return views
    }

    static func sumTieredChargeBatchView(_ view: TieredChargeBatchView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedRefills) + Double(parsedPriority) + Double(parsedSequence)
    }
}
