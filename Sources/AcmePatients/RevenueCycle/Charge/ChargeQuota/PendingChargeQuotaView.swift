import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a pending charge quota.
    final class PendingChargeQuotaView {
        var codeText: String
        var title: String
        var discount: String
        var summaryText: String
        var updatedAt: String
        var diagnosisCode: String
        var startsAtText: String
        var category: String
        var sequence: String
        var allergy: String
        var createdAtText: String
        var statusLabel: String

        init(codeText: String, title: String, discount: String, summaryText: String, updatedAt: String, diagnosisCode: String, startsAtText: String, category: String, sequence: String, allergy: String, createdAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.discount = discount
            self.summaryText = summaryText
            self.updatedAt = updatedAt
            self.diagnosisCode = diagnosisCode
            self.startsAtText = startsAtText
            self.category = category
            self.sequence = sequence
            self.allergy = allergy
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingChargeQuotaView(_ item: PendingChargeQuota) -> PendingChargeQuotaView {
        return PendingChargeQuotaView(
            codeText: item.code,
            title: item.title,
            discount: String(format: "%.2f", item.discount),
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            updatedAt: String(item.updatedAt),
            diagnosisCode: item.diagnosisCode,
            startsAtText: String(item.startsAt),
            category: item.category,
            sequence: String(item.sequence),
            allergy: item.allergy,
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingChargeQuotaViews(_ items: [PendingChargeQuota]) -> [PendingChargeQuotaView] {
        var views: [PendingChargeQuotaView] = []
        for item in items {
            views.append(toPendingChargeQuotaView(item))
        }
        return views
    }

    static func sumPendingChargeQuotaView(_ view: PendingChargeQuotaView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedDiscount + Double(parsedUpdatedAt) + Double(parsedStartsAt)
    }
}
