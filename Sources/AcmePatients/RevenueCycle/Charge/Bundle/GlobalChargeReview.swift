import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a global charge review is in its life cycle.
    enum GlobalChargeReviewStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One global charge review, with what the planners need to act on it.
    final class GlobalChargeReview {
        var code: String
        var name: String
        var title: String
        var active: Bool
        var segment: String
        var quantity: Int
        var status: GlobalChargeReviewStatus

        init(code: String, name: String, title: String, active: Bool, segment: String, quantity: Int, status: GlobalChargeReviewStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.active = active
            self.segment = segment
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalChargeReviewStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalChargeReviewStatus.published || next == GlobalChargeReviewStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: GlobalChargeReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global charge review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> GlobalChargeReview {
            return GlobalChargeReview(
                code: code,
                name: name,
                title: title,
                active: active,
                segment: segment,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a global charge review in status created.
    static func newGlobalChargeReview(_ code: String, name: String) -> GlobalChargeReview {
        return GlobalChargeReview(
            code: code,
            name: name,
            title: "",
            active: false,
            segment: "",
            quantity: 0,
            status: GlobalChargeReviewStatus.created
        )
    }
}
