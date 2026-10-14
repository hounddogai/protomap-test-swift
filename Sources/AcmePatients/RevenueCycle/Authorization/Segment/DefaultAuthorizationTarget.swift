import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default authorization target is in its life cycle.
    enum DefaultAuthorizationTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default authorization target and its current status.
    final class DefaultAuthorizationTarget {
        var code: String
        var title: String
        var cost: Double
        var ward: String
        var ratio: Double
        var threshold: Double
        var facility: String
        var allergy: String
        var discount: Double
        var status: DefaultAuthorizationTargetStatus

        init(code: String, title: String, cost: Double, ward: String, ratio: Double, threshold: Double, facility: String, allergy: String, discount: Double, status: DefaultAuthorizationTargetStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.ward = ward
            self.ratio = ratio
            self.threshold = threshold
            self.facility = facility
            self.allergy = allergy
            self.discount = discount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultAuthorizationTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultAuthorizationTargetStatus.inProgress || next == DefaultAuthorizationTargetStatus.completed
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: DefaultAuthorizationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default authorization target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return ((threshold + discount) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAuthorizationTarget {
            return DefaultAuthorizationTarget(
                code: code,
                title: title,
                cost: cost,
                ward: ward,
                ratio: ratio,
                threshold: threshold,
                facility: facility,
                allergy: allergy,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default authorization target in status planned.
    static func newDefaultAuthorizationTarget(_ code: String, title: String) -> DefaultAuthorizationTarget {
        return DefaultAuthorizationTarget(
            code: code,
            title: title,
            cost: 0.0,
            ward: "",
            ratio: 0.0,
            threshold: 0.0,
            facility: "",
            allergy: "",
            discount: 0.0,
            status: DefaultAuthorizationTargetStatus.planned
        )
    }
}
