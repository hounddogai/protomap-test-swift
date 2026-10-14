import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a weighted authorization request is in its life cycle.
    enum WeightedAuthorizationRequestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted authorization request as the authorization team keeps it.
    final class WeightedAuthorizationRequest {
        var code: String
        var title: String
        var minimum: Double
        var encounterID: String
        var acuity: Int
        var category: String
        var status: WeightedAuthorizationRequestStatus

        init(code: String, title: String, minimum: Double, encounterID: String, acuity: Int, category: String, status: WeightedAuthorizationRequestStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.encounterID = encounterID
            self.acuity = acuity
            self.category = category
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

        func canMoveTo(_ next: WeightedAuthorizationRequestStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedAuthorizationRequestStatus.resolved || next == WeightedAuthorizationRequestStatus.archived
            case .resolved:
                switch next {
                case .archived:
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

        func moveTo(_ next: WeightedAuthorizationRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted authorization request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted authorization request") \(code)"
        }

        func weightedLoad() -> Double {
            return (minimum * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAuthorizationRequest {
            return WeightedAuthorizationRequest(
                code: code,
                title: title,
                minimum: minimum,
                encounterID: encounterID,
                acuity: acuity,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a weighted authorization request in status open.
    static func newWeightedAuthorizationRequest(_ code: String, title: String) -> WeightedAuthorizationRequest {
        return WeightedAuthorizationRequest(
            code: code,
            title: title,
            minimum: 0.0,
            encounterID: "",
            acuity: 0,
            category: "",
            status: WeightedAuthorizationRequestStatus.`open`
        )
    }
}
