import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set threshold is in its life cycle.
    enum OrderSetThresholdStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A order set threshold as the order set team keeps it.
    final class OrderSetThreshold {
        var code: String
        var title: String
        var sequence: Int
        var priority: Int
        var reviewer: String
        var dosageMg: Double
        var status: OrderSetThresholdStatus

        init(code: String, title: String, sequence: Int, priority: Int, reviewer: String, dosageMg: Double, status: OrderSetThresholdStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.priority = priority
            self.reviewer = reviewer
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: OrderSetThresholdStatus) -> Bool {
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
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: OrderSetThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedValue() -> Double {
            return ((Double(priority) - Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetThreshold {
            return OrderSetThreshold(
                code: code,
                title: title,
                sequence: sequence,
                priority: priority,
                reviewer: reviewer,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a order set threshold in status proposed.
    static func newOrderSetThreshold(_ code: String, title: String) -> OrderSetThreshold {
        return OrderSetThreshold(
            code: code,
            title: title,
            sequence: 0,
            priority: 0,
            reviewer: "",
            dosageMg: 0.0,
            status: OrderSetThresholdStatus.proposed
        )
    }
}
