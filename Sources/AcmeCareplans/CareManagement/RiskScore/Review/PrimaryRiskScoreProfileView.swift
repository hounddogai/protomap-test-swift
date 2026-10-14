import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a primary risk score profile.
    final class PrimaryRiskScoreProfileView {
        var codeText: String
        var title: String
        var quantityText: String
        var bed: String
        var startsAt: String
        var ownerIDText: String
        var clinicianIDText: String
        var weightText: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, title: String, quantityText: String, bed: String, startsAt: String, ownerIDText: String, clinicianIDText: String, weightText: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.quantityText = quantityText
            self.bed = bed
            self.startsAt = startsAt
            self.ownerIDText = ownerIDText
            self.clinicianIDText = clinicianIDText
            self.weightText = weightText
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryRiskScoreProfileView(_ item: PrimaryRiskScoreProfile) -> PrimaryRiskScoreProfileView {
        return PrimaryRiskScoreProfileView(
            codeText: item.code,
            title: item.title,
            quantityText: String(item.quantity),
            bed: item.bed,
            startsAt: String(item.startsAt),
            ownerIDText: item.ownerID,
            clinicianIDText: item.clinicianID,
            weightText: String(format: "%.2f", item.weight),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryRiskScoreProfileViews(_ items: [PrimaryRiskScoreProfile]) -> [PrimaryRiskScoreProfileView] {
        var views: [PrimaryRiskScoreProfileView] = []
        for item in items {
            views.append(toPrimaryRiskScoreProfileView(item))
        }
        return views
    }

    static func sumPrimaryRiskScoreProfileView(_ view: PrimaryRiskScoreProfileView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedQuantity) + Double(parsedStartsAt) + parsedWeight
    }
}
