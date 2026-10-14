import AcmePlatform
import Foundation

extension Referrals {
    /// Where a slot cycle is in its life cycle.
    enum SlotCycleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a slot cycle and its current status.
    final class SlotCycle {
        var code: String
        var name: String
        var ceiling: Double
        var archived: Bool
        var graceDays: Int
        var label: String
        var attributes: [String: String]
        var status: SlotCycleStatus

        init(code: String, name: String, ceiling: Double, archived: Bool, graceDays: Int, label: String, attributes: [String: String], status: SlotCycleStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.archived = archived
            self.graceDays = graceDays
            self.label = label
            self.attributes = attributes
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

        func canMoveTo(_ next: SlotCycleStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SlotCycleStatus.suspended || next == SlotCycleStatus.closed
            case .suspended:
                return next == SlotCycleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SlotCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("slot cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(name)"
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

        func netLoad() -> Double {
            return ((Double(graceDays) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> SlotCycle {
            return SlotCycle(
                code: code,
                name: name,
                ceiling: ceiling,
                archived: archived,
                graceDays: graceDays,
                label: label,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a slot cycle in status draft.
    static func newSlotCycle(_ code: String, name: String) -> SlotCycle {
        return SlotCycle(
            code: code,
            name: name,
            ceiling: 0.0,
            archived: false,
            graceDays: 0,
            label: "",
            attributes: [:],
            status: SlotCycleStatus.draft
        )
    }
}
