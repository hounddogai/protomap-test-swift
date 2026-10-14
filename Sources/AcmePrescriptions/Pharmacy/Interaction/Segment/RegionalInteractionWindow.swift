import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional interaction window is in its life cycle.
    enum RegionalInteractionWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional interaction window as the interaction team keeps it.
    final class RegionalInteractionWindow {
        var code: String
        var title: String
        var acuity: Int
        var externalRef: String
        var archived: Bool
        var summary: String
        var status: RegionalInteractionWindowStatus

        init(code: String, title: String, acuity: Int, externalRef: String, archived: Bool, summary: String, status: RegionalInteractionWindowStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.externalRef = externalRef
            self.archived = archived
            self.summary = summary
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

        func canMoveTo(_ next: RegionalInteractionWindowStatus) -> Bool {
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
                return next == RegionalInteractionWindowStatus.suspended
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

        func moveTo(_ next: RegionalInteractionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional interaction window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> RegionalInteractionWindow {
            return RegionalInteractionWindow(
                code: code,
                title: title,
                acuity: acuity,
                externalRef: externalRef,
                archived: archived,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a regional interaction window in status draft.
    static func newRegionalInteractionWindow(_ code: String, title: String) -> RegionalInteractionWindow {
        return RegionalInteractionWindow(
            code: code,
            title: title,
            acuity: 0,
            externalRef: "",
            archived: false,
            summary: "",
            status: RegionalInteractionWindowStatus.draft
        )
    }
}
