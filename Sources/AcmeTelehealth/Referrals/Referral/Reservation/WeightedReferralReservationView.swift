import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted referral reservation.
    final class WeightedReferralReservationView {
        var code: String
        var title: String
        var createdAt: String
        var clinicianID: String
        var refillsText: String
        var attempts: String
        var notesText: String
        var approved: String
        var threshold: String
        var category: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, clinicianID: String, refillsText: String, attempts: String, notesText: String, approved: String, threshold: String, category: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.refillsText = refillsText
            self.attempts = attempts
            self.notesText = notesText
            self.approved = approved
            self.threshold = threshold
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReferralReservationView(_ item: WeightedReferralReservation) -> WeightedReferralReservationView {
        return WeightedReferralReservationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 64),
            createdAt: String(item.createdAt),
            clinicianID: item.clinicianID,
            refillsText: String(item.refills),
            attempts: String(item.attempts),
            notesText: item.notes,
            approved: "\(item.approved)",
            threshold: String(format: "%.2f", item.threshold),
            category: Kit.Text.truncate(item.category, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReferralReservationViews(_ items: [WeightedReferralReservation]) -> [WeightedReferralReservationView] {
        var views: [WeightedReferralReservationView] = []
        for item in items {
            views.append(toWeightedReferralReservationView(item))
        }
        return views
    }

    static func sumWeightedReferralReservationView(_ view: WeightedReferralReservationView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedRefills) + Double(parsedAttempts)
    }
}
