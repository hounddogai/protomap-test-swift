import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure template is in its life cycle.
    enum ClosureTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A closure template as the closure team keeps it.
    final class ClosureTemplate {
        var code: String
        var label: String
        var externalRef: String
        var visitMinutes: Int
        var timezone: String
        var status: ClosureTemplateStatus

        init(code: String, label: String, externalRef: String, visitMinutes: Int, timezone: String, status: ClosureTemplateStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.visitMinutes = visitMinutes
            self.timezone = timezone
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

        func canMoveTo(_ next: ClosureTemplateStatus) -> Bool {
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
                return next == ClosureTemplateStatus.suspended || next == ClosureTemplateStatus.closed
            case .active:
                switch next {
                case .suspended:
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

        func moveTo(_ next: ClosureTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> ClosureTemplate {
            return ClosureTemplate(
                code: code,
                label: label,
                externalRef: externalRef,
                visitMinutes: visitMinutes,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a closure template in status draft.
    static func newClosureTemplate(_ code: String, label: String) -> ClosureTemplate {
        return ClosureTemplate(
            code: code,
            label: label,
            externalRef: "",
            visitMinutes: 0,
            timezone: "",
            status: ClosureTemplateStatus.draft
        )
    }
}
