import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a pending alert tier is in its life cycle.
    enum PendingAlertTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One pending alert tier, with what the planners need to act on it.
    final class PendingAlertTier {
        var code: String
        var name: String
        var notes: String
        var phone: String
        var priority: Int
        var description: String
        var status: PendingAlertTierStatus

        init(code: String, name: String, notes: String, phone: String, priority: Int, description: String, status: PendingAlertTierStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.phone = phone
            self.priority = priority
            self.description = description
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

        func canMoveTo(_ next: PendingAlertTierStatus) -> Bool {
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
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: PendingAlertTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending alert tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("pending alert tier") \(code)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> PendingAlertTier {
            return PendingAlertTier(
                code: code,
                name: name,
                notes: notes,
                phone: phone,
                priority: priority,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a pending alert tier in status draft.
    static func newPendingAlertTier(_ code: String, name: String) -> PendingAlertTier {
        return PendingAlertTier(
            code: code,
            name: name,
            notes: "",
            phone: "",
            priority: 0,
            description: "",
            status: PendingAlertTierStatus.draft
        )
    }
}
