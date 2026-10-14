import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task claim is in its life cycle.
    enum TaskClaimStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A task claim. Its code is unique within a tenant.
    final class TaskClaim {
        var code: String
        var name: String
        var capacity: Int
        var patientRef: String
        var quantity: Int
        var ratio: Double
        var status: TaskClaimStatus

        init(code: String, name: String, capacity: Int, patientRef: String, quantity: Int, ratio: Double, status: TaskClaimStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.patientRef = patientRef
            self.quantity = quantity
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TaskClaimStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TaskClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netVolume() -> Double {
            return ((Double(capacity) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> TaskClaim {
            return TaskClaim(
                code: code,
                name: name,
                capacity: capacity,
                patientRef: patientRef,
                quantity: quantity,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a task claim in status draft.
    static func newTaskClaim(_ code: String, name: String) -> TaskClaim {
        return TaskClaim(
            code: code,
            name: name,
            capacity: 0,
            patientRef: "",
            quantity: 0,
            ratio: 0.0,
            status: TaskClaimStatus.draft
        )
    }
}
