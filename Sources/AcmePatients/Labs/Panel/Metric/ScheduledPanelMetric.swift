import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled panel metric is in its life cycle.
    enum ScheduledPanelMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One scheduled panel metric, with what the planners need to act on it.
    final class ScheduledPanelMetric {
        var code: String
        var label: String
        var quantity: Int
        var ownerID: String
        var archived: Bool
        var title: String
        var copay: Double
        var status: ScheduledPanelMetricStatus

        init(code: String, label: String, quantity: Int, ownerID: String, archived: Bool, title: String, copay: Double, status: ScheduledPanelMetricStatus) {
            self.code = code
            self.label = label
            self.quantity = quantity
            self.ownerID = ownerID
            self.archived = archived
            self.title = title
            self.copay = copay
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledPanelMetricStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ScheduledPanelMetricStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledPanelMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled panel metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return (copay * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledPanelMetric {
            return ScheduledPanelMetric(
                code: code,
                label: label,
                quantity: quantity,
                ownerID: ownerID,
                archived: archived,
                title: title,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled panel metric in status proposed.
    static func newScheduledPanelMetric(_ code: String, label: String) -> ScheduledPanelMetric {
        return ScheduledPanelMetric(
            code: code,
            label: label,
            quantity: 0,
            ownerID: "",
            archived: false,
            title: "",
            copay: 0.0,
            status: ScheduledPanelMetricStatus.proposed
        )
    }
}
