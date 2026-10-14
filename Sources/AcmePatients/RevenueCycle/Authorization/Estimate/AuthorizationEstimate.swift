import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization estimate is in its life cycle.
    enum AuthorizationEstimateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A authorization estimate. Its code is unique within a tenant.
    final class AuthorizationEstimate {
        var code: String
        var title: String
        var notes: String
        var category: String
        var rate: Double
        var weight: Double
        var status: AuthorizationEstimateStatus

        init(code: String, title: String, notes: String, category: String, rate: Double, weight: Double, status: AuthorizationEstimateStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.category = category
            self.rate = rate
            self.weight = weight
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

        func canMoveTo(_ next: AuthorizationEstimateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AuthorizationEstimateStatus.inReview
            case .inReview:
                return next == AuthorizationEstimateStatus.reopened
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

        func moveTo(_ next: AuthorizationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveValue() -> Double {
            return (weight * rate * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationEstimate {
            return AuthorizationEstimate(
                code: code,
                title: title,
                notes: notes,
                category: category,
                rate: rate,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a authorization estimate in status open.
    static func newAuthorizationEstimate(_ code: String, title: String) -> AuthorizationEstimate {
        return AuthorizationEstimate(
            code: code,
            title: title,
            notes: "",
            category: "",
            rate: 0.0,
            weight: 0.0,
            status: AuthorizationEstimateStatus.`open`
        )
    }
}
