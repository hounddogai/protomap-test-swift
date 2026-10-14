import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a revocation agreement.
    final class RevocationAgreementView {
        var codeText: String
        var labelText: String
        var pinned: String
        var budget: String
        var weight: String
        var endsAt: String
        var bed: String
        var capacityText: String
        var visitMinutesText: String
        var statusLabel: String

        init(codeText: String, labelText: String, pinned: String, budget: String, weight: String, endsAt: String, bed: String, capacityText: String, visitMinutesText: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.pinned = pinned
            self.budget = budget
            self.weight = weight
            self.endsAt = endsAt
            self.bed = bed
            self.capacityText = capacityText
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toRevocationAgreementView(_ item: RevocationAgreement) -> RevocationAgreementView {
        return RevocationAgreementView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            pinned: "\(item.pinned)",
            budget: String(format: "%.2f", item.budget),
            weight: String(format: "%.2f", item.weight),
            endsAt: String(item.endsAt),
            bed: Kit.Text.truncate(item.bed, limit: 120),
            capacityText: String(item.capacity),
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRevocationAgreementViews(_ items: [RevocationAgreement]) -> [RevocationAgreementView] {
        var views: [RevocationAgreementView] = []
        for item in items {
            views.append(toRevocationAgreementView(item))
        }
        return views
    }

    static func sumRevocationAgreementView(_ view: RevocationAgreementView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedBudget + parsedWeight + Double(parsedEndsAt)
    }
}
