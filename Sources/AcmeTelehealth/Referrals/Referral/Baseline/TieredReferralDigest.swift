import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered referral digest is in its life cycle.
    enum TieredReferralDigestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered referral digest and its current status.
    final class TieredReferralDigest {
        var code: String
        var title: String
        var minimum: Double
        var clinicianID: String
        var phone: String
        var updatedAt: Int
        var label: String
        var source: String
        var specialty: String
        var revision: Int
        var status: TieredReferralDigestStatus

        init(code: String, title: String, minimum: Double, clinicianID: String, phone: String, updatedAt: Int, label: String, source: String, specialty: String, revision: Int, status: TieredReferralDigestStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.clinicianID = clinicianID
            self.phone = phone
            self.updatedAt = updatedAt
            self.label = label
            self.source = source
            self.specialty = specialty
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredReferralDigestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == TieredReferralDigestStatus.suspended
            case .suspended:
                return next == TieredReferralDigestStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReferralDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered referral digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return (Double(revision) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> TieredReferralDigest {
            return TieredReferralDigest(
                code: code,
                title: title,
                minimum: minimum,
                clinicianID: clinicianID,
                phone: phone,
                updatedAt: updatedAt,
                label: label,
                source: source,
                specialty: specialty,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a tiered referral digest in status draft.
    static func newTieredReferralDigest(_ code: String, title: String) -> TieredReferralDigest {
        return TieredReferralDigest(
            code: code,
            title: title,
            minimum: 0.0,
            clinicianID: "",
            phone: "",
            updatedAt: 0,
            label: "",
            source: "",
            specialty: "",
            revision: 0,
            status: TieredReferralDigestStatus.draft
        )
    }
}
