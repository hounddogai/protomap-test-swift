import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a statement slot is in its life cycle.
    enum StatementSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a statement slot and its current status.
    final class StatementSlot {
        var code: String
        var label: String
        var cost: Double
        var version: Int
        var threshold: Double
        var status: StatementSlotStatus

        init(code: String, label: String, cost: Double, version: Int, threshold: Double, status: StatementSlotStatus) {
            self.code = code
            self.label = label
            self.cost = cost
            self.version = version
            self.threshold = threshold
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

        func canMoveTo(_ next: StatementSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == StatementSlotStatus.published || next == StatementSlotStatus.retired
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: StatementSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("statement slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("statement slot") \(code)"
        }

        func effectiveTotal() -> Double {
            return ((threshold - cost) * 100).rounded() / 100
        }

        func copyValue() -> StatementSlot {
            return StatementSlot(
                code: code,
                label: label,
                cost: cost,
                version: version,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a statement slot in status created.
    static func newStatementSlot(_ code: String, label: String) -> StatementSlot {
        return StatementSlot(
            code: code,
            label: label,
            cost: 0.0,
            version: 0,
            threshold: 0.0,
            status: StatementSlotStatus.created
        )
    }
}
