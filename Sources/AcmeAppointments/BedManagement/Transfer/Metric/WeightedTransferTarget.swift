import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted transfer target is in its life cycle.
    enum WeightedTransferTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A weighted transfer target. Its code is unique within a tenant.
    final class WeightedTransferTarget {
        var code: String
        var label: String
        var maximum: Double
        var ceiling: Double
        var name: String
        var pinned: Bool
        var locale: String
        var durationMinutes: Int
        var amount: Double
        var discount: Double
        var status: WeightedTransferTargetStatus

        init(code: String, label: String, maximum: Double, ceiling: Double, name: String, pinned: Bool, locale: String, durationMinutes: Int, amount: Double, discount: Double, status: WeightedTransferTargetStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.ceiling = ceiling
            self.name = name
            self.pinned = pinned
            self.locale = locale
            self.durationMinutes = durationMinutes
            self.amount = amount
            self.discount = discount
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

        func canMoveTo(_ next: WeightedTransferTargetStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == WeightedTransferTargetStatus.reopened
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == WeightedTransferTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTransferTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted transfer target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedLoad() -> Double {
            return ((discount + amount) * 100).rounded() / 100
        }

        func copyValue() -> WeightedTransferTarget {
            return WeightedTransferTarget(
                code: code,
                label: label,
                maximum: maximum,
                ceiling: ceiling,
                name: name,
                pinned: pinned,
                locale: locale,
                durationMinutes: durationMinutes,
                amount: amount,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a weighted transfer target in status open.
    static func newWeightedTransferTarget(_ code: String, label: String) -> WeightedTransferTarget {
        return WeightedTransferTarget(
            code: code,
            label: label,
            maximum: 0.0,
            ceiling: 0.0,
            name: "",
            pinned: false,
            locale: "",
            durationMinutes: 0,
            amount: 0.0,
            discount: 0.0,
            status: WeightedTransferTargetStatus.`open`
        )
    }
}
