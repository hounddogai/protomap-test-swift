import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert mapping is in its life cycle.
    enum AlertMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One alert mapping, with what the planners need to act on it.
    final class AlertMapping {
        var code: String
        var title: String
        var phone: String
        var cost: Double
        var visible: Bool
        var ceiling: Double
        var ratio: Double
        var maximum: Double
        var status: AlertMappingStatus

        init(code: String, title: String, phone: String, cost: Double, visible: Bool, ceiling: Double, ratio: Double, maximum: Double, status: AlertMappingStatus) {
            self.code = code
            self.title = title
            self.phone = phone
            self.cost = cost
            self.visible = visible
            self.ceiling = ceiling
            self.ratio = ratio
            self.maximum = maximum
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

        func canMoveTo(_ next: AlertMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: AlertMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedLoad() -> Double {
            return ((ceiling + maximum) * 100).rounded() / 100
        }

        func copyValue() -> AlertMapping {
            return AlertMapping(
                code: code,
                title: title,
                phone: phone,
                cost: cost,
                visible: visible,
                ceiling: ceiling,
                ratio: ratio,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert mapping in status planned.
    static func newAlertMapping(_ code: String, title: String) -> AlertMapping {
        return AlertMapping(
            code: code,
            title: title,
            phone: "",
            cost: 0.0,
            visible: false,
            ceiling: 0.0,
            ratio: 0.0,
            maximum: 0.0,
            status: AlertMappingStatus.planned
        )
    }
}
