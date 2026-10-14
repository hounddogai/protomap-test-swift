import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a capped charge estimate.
    final class CappedChargeEstimateView {
        var code: String
        var title: String
        var allergy: String
        var revision: String
        var ownerID: String
        var durationMinutes: String
        var facilityText: String
        var limit: String
        var endsAtText: String
        var acuity: String
        var clinicianID: String
        var statusLabel: String

        init(code: String, title: String, allergy: String, revision: String, ownerID: String, durationMinutes: String, facilityText: String, limit: String, endsAtText: String, acuity: String, clinicianID: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.allergy = allergy
            self.revision = revision
            self.ownerID = ownerID
            self.durationMinutes = durationMinutes
            self.facilityText = facilityText
            self.limit = limit
            self.endsAtText = endsAtText
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.statusLabel = statusLabel
        }
    }

    static func toCappedChargeEstimateView(_ item: CappedChargeEstimate) -> CappedChargeEstimateView {
        return CappedChargeEstimateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            allergy: item.allergy,
            revision: String(item.revision),
            ownerID: item.ownerID,
            durationMinutes: String(item.durationMinutes),
            facilityText: item.facility,
            limit: String(item.limit),
            endsAtText: String(item.endsAt),
            acuity: String(item.acuity),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedChargeEstimateViews(_ items: [CappedChargeEstimate]) -> [CappedChargeEstimateView] {
        var views: [CappedChargeEstimateView] = []
        for item in items {
            views.append(toCappedChargeEstimateView(item))
        }
        return views
    }

    static func sumCappedChargeEstimateView(_ view: CappedChargeEstimateView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedRevision) + Double(parsedDurationMinutes) + Double(parsedLimit)
    }
}
