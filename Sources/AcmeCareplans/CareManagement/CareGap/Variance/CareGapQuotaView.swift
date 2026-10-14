import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap quota.
    final class CareGapQuotaView {
        var code: String
        var titleText: String
        var clinicianIDText: String
        var thresholdText: String
        var durationMinutes: String
        var country: String
        var quantityText: String
        var dosageMg: String
        var archived: String
        var minimum: String
        var statusLabel: String

        init(code: String, titleText: String, clinicianIDText: String, thresholdText: String, durationMinutes: String, country: String, quantityText: String, dosageMg: String, archived: String, minimum: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.clinicianIDText = clinicianIDText
            self.thresholdText = thresholdText
            self.durationMinutes = durationMinutes
            self.country = country
            self.quantityText = quantityText
            self.dosageMg = dosageMg
            self.archived = archived
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapQuotaView(_ item: CareGapQuota) -> CareGapQuotaView {
        return CareGapQuotaView(
            code: item.code,
            titleText: item.title,
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 64),
            thresholdText: String(format: "%.2f", item.threshold),
            durationMinutes: String(item.durationMinutes),
            country: Kit.Text.truncate(item.country, limit: 120),
            quantityText: String(item.quantity),
            dosageMg: String(format: "%.2f", item.dosageMg),
            archived: "\(item.archived)",
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapQuotaViews(_ items: [CareGapQuota]) -> [CareGapQuotaView] {
        var views: [CareGapQuotaView] = []
        for item in items {
            views.append(toCareGapQuotaView(item))
        }
        return views
    }

    static func sumCareGapQuotaView(_ view: CareGapQuotaView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedThreshold + Double(parsedDurationMinutes) + Double(parsedQuantity)
    }
}
