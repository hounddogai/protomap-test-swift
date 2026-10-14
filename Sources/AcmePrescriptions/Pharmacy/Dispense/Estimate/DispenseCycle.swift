import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense cycle is in its life cycle.
    enum DispenseCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A dispense cycle as the dispense team keeps it.
    final class DispenseCycle {
        var code: String
        var title: String
        var copay: Double
        var archived: Bool
        var capacity: Int
        var active: Bool
        var status: DispenseCycleStatus

        init(code: String, title: String, copay: Double, archived: Bool, capacity: Int, active: Bool, status: DispenseCycleStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.archived = archived
            self.capacity = capacity
            self.active = active
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseCycleStatus) -> Bool {
            switch status {
            case .new:
                return next == DispenseCycleStatus.running
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == DispenseCycleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("dispense cycle") \(code)"
        }

        func adjustedValue() -> Double {
            return (copay * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> DispenseCycle {
            return DispenseCycle(
                code: code,
                title: title,
                copay: copay,
                archived: archived,
                capacity: capacity,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense cycle in status new.
    static func newDispenseCycle(_ code: String, title: String) -> DispenseCycle {
        return DispenseCycle(
            code: code,
            title: title,
            copay: 0.0,
            archived: false,
            capacity: 0,
            active: false,
            status: DispenseCycleStatus.new
        )
    }
}
