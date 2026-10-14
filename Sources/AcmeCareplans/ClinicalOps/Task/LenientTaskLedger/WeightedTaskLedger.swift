import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a weighted task ledger is in its life cycle.
    enum WeightedTaskLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted task ledger. Its code is unique within a tenant.
    final class WeightedTaskLedger {
        var code: String
        var title: String
        var attributes: [String: String]
        var cost: Double
        var approved: Bool
        var notes: String
        var pinned: Bool
        var visible: Bool
        var channel: String
        var status: WeightedTaskLedgerStatus

        init(code: String, title: String, attributes: [String: String], cost: Double, approved: Bool, notes: String, pinned: Bool, visible: Bool, channel: String, status: WeightedTaskLedgerStatus) {
            self.code = code
            self.title = title
            self.attributes = attributes
            self.cost = cost
            self.approved = approved
            self.notes = notes
            self.pinned = pinned
            self.visible = visible
            self.channel = channel
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

        func canMoveTo(_ next: WeightedTaskLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WeightedTaskLedgerStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedTaskLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted task ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted task ledger") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return cost
        }

        func copyValue() -> WeightedTaskLedger {
            return WeightedTaskLedger(
                code: code,
                title: title,
                attributes: attributes,
                cost: cost,
                approved: approved,
                notes: notes,
                pinned: pinned,
                visible: visible,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted task ledger in status proposed.
    static func newWeightedTaskLedger(_ code: String, title: String) -> WeightedTaskLedger {
        return WeightedTaskLedger(
            code: code,
            title: title,
            attributes: [:],
            cost: 0.0,
            approved: false,
            notes: "",
            pinned: false,
            visible: false,
            channel: "",
            status: WeightedTaskLedgerStatus.proposed
        )
    }
}
