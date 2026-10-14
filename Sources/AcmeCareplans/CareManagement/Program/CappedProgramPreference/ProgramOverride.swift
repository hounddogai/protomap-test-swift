import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program override is in its life cycle.
    enum ProgramOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A program override as the program team keeps it.
    final class ProgramOverride {
        var code: String
        var name: String
        var priority: Int
        var visible: Bool
        var limit: Int
        var status: ProgramOverrideStatus

        init(code: String, name: String, priority: Int, visible: Bool, limit: Int, status: ProgramOverrideStatus) {
            self.code = code
            self.name = name
            self.priority = priority
            self.visible = visible
            self.limit = limit
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

        func canMoveTo(_ next: ProgramOverrideStatus) -> Bool {
            switch status {
            case .draft:
                return next == ProgramOverrideStatus.suspended
            case .pending:
                return next == ProgramOverrideStatus.suspended || next == ProgramOverrideStatus.closed
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

        func moveTo(_ next: ProgramOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("program override") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(limit) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> ProgramOverride {
            return ProgramOverride(
                code: code,
                name: name,
                priority: priority,
                visible: visible,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a program override in status draft.
    static func newProgramOverride(_ code: String, name: String) -> ProgramOverride {
        return ProgramOverride(
            code: code,
            name: name,
            priority: 0,
            visible: false,
            limit: 0,
            status: ProgramOverrideStatus.draft
        )
    }
}
