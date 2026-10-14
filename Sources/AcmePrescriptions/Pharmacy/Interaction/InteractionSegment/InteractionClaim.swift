import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction claim is in its life cycle.
    enum InteractionClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A interaction claim as the interaction team keeps it.
    final class InteractionClaim {
        var code: String
        var title: String
        var contactEmail: String
        var threshold: Double
        var channel: String
        var graceDays: Int
        var ceiling: Double
        var dosageMg: Double
        var budget: Double
        var weight: Double
        var status: InteractionClaimStatus

        init(code: String, title: String, contactEmail: String, threshold: Double, channel: String, graceDays: Int, ceiling: Double, dosageMg: Double, budget: Double, weight: Double, status: InteractionClaimStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.threshold = threshold
            self.channel = channel
            self.graceDays = graceDays
            self.ceiling = ceiling
            self.dosageMg = dosageMg
            self.budget = budget
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

        func canMoveTo(_ next: InteractionClaimStatus) -> Bool {
            switch status {
            case .`open`:
                return next == InteractionClaimStatus.inReview
            case .inReview:
                switch next {
                case .resolved:
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

        func moveTo(_ next: InteractionClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netVolume() -> Double {
            return ((weight + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> InteractionClaim {
            return InteractionClaim(
                code: code,
                title: title,
                contactEmail: contactEmail,
                threshold: threshold,
                channel: channel,
                graceDays: graceDays,
                ceiling: ceiling,
                dosageMg: dosageMg,
                budget: budget,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a interaction claim in status open.
    static func newInteractionClaim(_ code: String, title: String) -> InteractionClaim {
        return InteractionClaim(
            code: code,
            title: title,
            contactEmail: "",
            threshold: 0.0,
            channel: "",
            graceDays: 0,
            ceiling: 0.0,
            dosageMg: 0.0,
            budget: 0.0,
            weight: 0.0,
            status: InteractionClaimStatus.`open`
        )
    }
}
