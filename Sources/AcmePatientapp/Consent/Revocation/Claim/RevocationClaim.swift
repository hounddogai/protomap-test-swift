import AcmePlatform
import Foundation

extension Consent {
    /// Where a revocation claim is in its life cycle.
    enum RevocationClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a revocation claim and its current status.
    final class RevocationClaim {
        var code: String
        var title: String
        var revision: Int
        var timezone: String
        var acuity: Int
        var graceDays: Int
        var createdAt: Int
        var reviewer: String
        var quantity: Int
        var status: RevocationClaimStatus

        init(code: String, title: String, revision: Int, timezone: String, acuity: Int, graceDays: Int, createdAt: Int, reviewer: String, quantity: Int, status: RevocationClaimStatus) {
            self.code = code
            self.title = title
            self.revision = revision
            self.timezone = timezone
            self.acuity = acuity
            self.graceDays = graceDays
            self.createdAt = createdAt
            self.reviewer = reviewer
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RevocationClaimStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RevocationClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("revocation claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\("revocation claim") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(graceDays) + Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> RevocationClaim {
            return RevocationClaim(
                code: code,
                title: title,
                revision: revision,
                timezone: timezone,
                acuity: acuity,
                graceDays: graceDays,
                createdAt: createdAt,
                reviewer: reviewer,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a revocation claim in status open.
    static func newRevocationClaim(_ code: String, title: String) -> RevocationClaim {
        return RevocationClaim(
            code: code,
            title: title,
            revision: 0,
            timezone: "",
            acuity: 0,
            graceDays: 0,
            createdAt: 0,
            reviewer: "",
            quantity: 0,
            status: RevocationClaimStatus.`open`
        )
    }
}
