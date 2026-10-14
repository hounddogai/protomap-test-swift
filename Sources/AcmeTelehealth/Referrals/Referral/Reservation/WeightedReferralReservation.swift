import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral reservation is in its life cycle.
    enum WeightedReferralReservationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted referral reservation as the referral team keeps it.
    final class WeightedReferralReservation {
        var code: String
        var title: String
        var createdAt: Int
        var clinicianID: String
        var refills: Int
        var attempts: Int
        var notes: String
        var approved: Bool
        var threshold: Double
        var category: String
        var status: WeightedReferralReservationStatus

        init(code: String, title: String, createdAt: Int, clinicianID: String, refills: Int, attempts: Int, notes: String, approved: Bool, threshold: Double, category: String, status: WeightedReferralReservationStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.clinicianID = clinicianID
            self.refills = refills
            self.attempts = attempts
            self.notes = notes
            self.approved = approved
            self.threshold = threshold
            self.category = category
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedReferralReservationStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedReferralReservationStatus.revoked || next == WeightedReferralReservationStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedReferralReservationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedReferralReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return (Double(refills) * Double(createdAt) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralReservation {
            return WeightedReferralReservation(
                code: code,
                title: title,
                createdAt: createdAt,
                clinicianID: clinicianID,
                refills: refills,
                attempts: attempts,
                notes: notes,
                approved: approved,
                threshold: threshold,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted referral reservation in status requested.
    static func newWeightedReferralReservation(_ code: String, title: String) -> WeightedReferralReservation {
        return WeightedReferralReservation(
            code: code,
            title: title,
            createdAt: 0,
            clinicianID: "",
            refills: 0,
            attempts: 0,
            notes: "",
            approved: false,
            threshold: 0.0,
            category: "",
            status: WeightedReferralReservationStatus.requested
        )
    }
}
