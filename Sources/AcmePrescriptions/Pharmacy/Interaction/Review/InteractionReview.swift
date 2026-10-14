import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction review is in its life cycle.
    enum InteractionReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A interaction review as the interaction team keeps it.
    final class InteractionReview {
        var code: String
        var label: String
        var title: String
        var retries: Int
        var margin: Double
        var cost: Double
        var status: InteractionReviewStatus

        init(code: String, label: String, title: String, retries: Int, margin: Double, cost: Double, status: InteractionReviewStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.retries = retries
            self.margin = margin
            self.cost = cost
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

        func canMoveTo(_ next: InteractionReviewStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == InteractionReviewStatus.resolved || next == InteractionReviewStatus.archived
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

        func moveTo(_ next: InteractionReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedVolume() -> Double {
            return ((Double(retries) + cost) * 100).rounded() / 100
        }

        func copyValue() -> InteractionReview {
            return InteractionReview(
                code: code,
                label: label,
                title: title,
                retries: retries,
                margin: margin,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a interaction review in status open.
    static func newInteractionReview(_ code: String, label: String) -> InteractionReview {
        return InteractionReview(
            code: code,
            label: label,
            title: "",
            retries: 0,
            margin: 0.0,
            cost: 0.0,
            status: InteractionReviewStatus.`open`
        )
    }
}
