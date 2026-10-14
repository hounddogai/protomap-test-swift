import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation template is in its life cycle.
    enum IsolationTemplateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One isolation template, with what the planners need to act on it.
    final class IsolationTemplate {
        var code: String
        var label: String
        var name: String
        var threshold: Double
        var score: Double
        var source: String
        var procedureCode: String
        var status: IsolationTemplateStatus

        init(code: String, label: String, name: String, threshold: Double, score: Double, source: String, procedureCode: String, status: IsolationTemplateStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.threshold = threshold
            self.score = score
            self.source = source
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: IsolationTemplateStatus) -> Bool {
            switch status {
            case .draft:
                return next == IsolationTemplateStatus.pending || next == IsolationTemplateStatus.suspended
            case .pending:
                return next == IsolationTemplateStatus.active
            case .active:
                return next == IsolationTemplateStatus.suspended || next == IsolationTemplateStatus.closed
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

        func moveTo(_ next: IsolationTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((score + threshold) * 100).rounded() / 100
        }

        func copyValue() -> IsolationTemplate {
            return IsolationTemplate(
                code: code,
                label: label,
                name: name,
                threshold: threshold,
                score: score,
                source: source,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a isolation template in status draft.
    static func newIsolationTemplate(_ code: String, label: String) -> IsolationTemplate {
        return IsolationTemplate(
            code: code,
            label: label,
            name: "",
            threshold: 0.0,
            score: 0.0,
            source: "",
            procedureCode: "",
            status: IsolationTemplateStatus.draft
        )
    }
}
