import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert baseline is in its life cycle.
    enum AlertBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A alert baseline as the alert team keeps it.
    final class AlertBaseline {
        var code: String
        var title: String
        var minimum: Double
        var description: String
        var clinicianID: String
        var sequence: Int
        var discount: Double
        var capacity: Int
        var status: AlertBaselineStatus

        init(code: String, title: String, minimum: Double, description: String, clinicianID: String, sequence: Int, discount: Double, capacity: Int, status: AlertBaselineStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.description = description
            self.clinicianID = clinicianID
            self.sequence = sequence
            self.discount = discount
            self.capacity = capacity
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

        func canMoveTo(_ next: AlertBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == AlertBaselineStatus.completed
            case .scheduled:
                return next == AlertBaselineStatus.inProgress
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

        func moveTo(_ next: AlertBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((minimum - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> AlertBaseline {
            return AlertBaseline(
                code: code,
                title: title,
                minimum: minimum,
                description: description,
                clinicianID: clinicianID,
                sequence: sequence,
                discount: discount,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a alert baseline in status planned.
    static func newAlertBaseline(_ code: String, title: String) -> AlertBaseline {
        return AlertBaseline(
            code: code,
            title: title,
            minimum: 0.0,
            description: "",
            clinicianID: "",
            sequence: 0,
            discount: 0.0,
            capacity: 0,
            status: AlertBaselineStatus.planned
        )
    }
}
