import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority threshold is in its life cycle.
    enum PriorityThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a priority threshold and its current status.
    final class PriorityThreshold {
        var code: String
        var name: String
        var rate: Double
        var priority: Int
        var updatedAt: Int
        var status: PriorityThresholdStatus

        init(code: String, name: String, rate: Double, priority: Int, updatedAt: Int, status: PriorityThresholdStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.priority = priority
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: PriorityThresholdStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PriorityThresholdStatus.active
            case .active:
                return next == PriorityThresholdStatus.suspended || next == PriorityThresholdStatus.closed
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

        func moveTo(_ next: PriorityThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("priority threshold") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(priority) + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> PriorityThreshold {
            return PriorityThreshold(
                code: code,
                name: name,
                rate: rate,
                priority: priority,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a priority threshold in status draft.
    static func newPriorityThreshold(_ code: String, name: String) -> PriorityThreshold {
        return PriorityThreshold(
            code: code,
            name: name,
            rate: 0.0,
            priority: 0,
            updatedAt: 0,
            status: PriorityThresholdStatus.draft
        )
    }
}
