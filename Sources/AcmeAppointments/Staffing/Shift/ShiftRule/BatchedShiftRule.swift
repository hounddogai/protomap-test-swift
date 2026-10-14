import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched shift rule is in its life cycle.
    enum BatchedShiftRuleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A batched shift rule. Its code is unique within a tenant.
    final class BatchedShiftRule {
        var code: String
        var name: String
        var margin: Double
        var source: String
        var priority: Int
        var checksum: String
        var channel: String
        var ownerID: String
        var cost: Double
        var status: BatchedShiftRuleStatus

        init(code: String, name: String, margin: Double, source: String, priority: Int, checksum: String, channel: String, ownerID: String, cost: Double, status: BatchedShiftRuleStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.source = source
            self.priority = priority
            self.checksum = checksum
            self.channel = channel
            self.ownerID = ownerID
            self.cost = cost
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

        func canMoveTo(_ next: BatchedShiftRuleStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == BatchedShiftRuleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedShiftRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched shift rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return ((Double(priority) + cost) * 100).rounded() / 100
        }

        func copyValue() -> BatchedShiftRule {
            return BatchedShiftRule(
                code: code,
                name: name,
                margin: margin,
                source: source,
                priority: priority,
                checksum: checksum,
                channel: channel,
                ownerID: ownerID,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a batched shift rule in status created.
    static func newBatchedShiftRule(_ code: String, name: String) -> BatchedShiftRule {
        return BatchedShiftRule(
            code: code,
            name: name,
            margin: 0.0,
            source: "",
            priority: 0,
            checksum: "",
            channel: "",
            ownerID: "",
            cost: 0.0,
            status: BatchedShiftRuleStatus.created
        )
    }
}
