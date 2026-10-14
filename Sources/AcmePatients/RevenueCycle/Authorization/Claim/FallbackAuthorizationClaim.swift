import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a fallback authorization claim is in its life cycle.
    enum FallbackAuthorizationClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback authorization claim, with what the planners need to act on it.
    final class FallbackAuthorizationClaim {
        var code: String
        var title: String
        var discount: Double
        var bed: String
        var amount: Double
        var floorValue: Double
        var status: FallbackAuthorizationClaimStatus

        init(code: String, title: String, discount: Double, bed: String, amount: Double, floorValue: Double, status: FallbackAuthorizationClaimStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.bed = bed
            self.amount = amount
            self.floorValue = floorValue
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

        func canMoveTo(_ next: FallbackAuthorizationClaimStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == FallbackAuthorizationClaimStatus.reopened || next == FallbackAuthorizationClaimStatus.archived
            case .resolved:
                return next == FallbackAuthorizationClaimStatus.reopened || next == FallbackAuthorizationClaimStatus.archived
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

        func moveTo(_ next: FallbackAuthorizationClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback authorization claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveValue() -> Double {
            return ((floorValue - discount) * 100).rounded() / 100
        }

        func copyValue() -> FallbackAuthorizationClaim {
            return FallbackAuthorizationClaim(
                code: code,
                title: title,
                discount: discount,
                bed: bed,
                amount: amount,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback authorization claim in status open.
    static func newFallbackAuthorizationClaim(_ code: String, title: String) -> FallbackAuthorizationClaim {
        return FallbackAuthorizationClaim(
            code: code,
            title: title,
            discount: 0.0,
            bed: "",
            amount: 0.0,
            floorValue: 0.0,
            status: FallbackAuthorizationClaimStatus.`open`
        )
    }
}
