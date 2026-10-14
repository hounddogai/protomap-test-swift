import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral score is in its life cycle.
    enum ReferralScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A referral score. Its code is unique within a tenant.
    final class ReferralScore {
        var code: String
        var label: String
        var clinicianID: String
        var revision: Int
        var ward: String
        var limit: Int
        var ownerID: String
        var expiresAt: Int
        var windowDays: Int
        var weight: Double
        var status: ReferralScoreStatus

        init(code: String, label: String, clinicianID: String, revision: Int, ward: String, limit: Int, ownerID: String, expiresAt: Int, windowDays: Int, weight: Double, status: ReferralScoreStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.revision = revision
            self.ward = ward
            self.limit = limit
            self.ownerID = ownerID
            self.expiresAt = expiresAt
            self.windowDays = windowDays
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferralScoreStatus) -> Bool {
            switch status {
            case .new:
                return next == ReferralScoreStatus.queued || next == ReferralScoreStatus.running
            case .queued:
                return next == ReferralScoreStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ReferralScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return ((Double(limit) - weight) * 100).rounded() / 100
        }

        func copyValue() -> ReferralScore {
            return ReferralScore(
                code: code,
                label: label,
                clinicianID: clinicianID,
                revision: revision,
                ward: ward,
                limit: limit,
                ownerID: ownerID,
                expiresAt: expiresAt,
                windowDays: windowDays,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a referral score in status new.
    static func newReferralScore(_ code: String, label: String) -> ReferralScore {
        return ReferralScore(
            code: code,
            label: label,
            clinicianID: "",
            revision: 0,
            ward: "",
            limit: 0,
            ownerID: "",
            expiresAt: 0,
            windowDays: 0,
            weight: 0.0,
            status: ReferralScoreStatus.new
        )
    }
}
