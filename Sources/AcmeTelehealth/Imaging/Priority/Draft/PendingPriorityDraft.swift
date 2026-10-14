import AcmePlatform
import Foundation

extension Imaging {
    /// Where a pending priority draft is in its life cycle.
    enum PendingPriorityDraftStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a pending priority draft and its current status.
    final class PendingPriorityDraft {
        var code: String
        var title: String
        var procedureCode: String
        var cost: Double
        var capacity: Int
        var status: PendingPriorityDraftStatus

        init(code: String, title: String, procedureCode: String, cost: Double, capacity: Int, status: PendingPriorityDraftStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.cost = cost
            self.capacity = capacity
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

        func canMoveTo(_ next: PendingPriorityDraftStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
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

        func moveTo(_ next: PendingPriorityDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending priority draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return (cost * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> PendingPriorityDraft {
            return PendingPriorityDraft(
                code: code,
                title: title,
                procedureCode: procedureCode,
                cost: cost,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending priority draft in status proposed.
    static func newPendingPriorityDraft(_ code: String, title: String) -> PendingPriorityDraft {
        return PendingPriorityDraft(
            code: code,
            title: title,
            procedureCode: "",
            cost: 0.0,
            capacity: 0,
            status: PendingPriorityDraftStatus.proposed
        )
    }
}
