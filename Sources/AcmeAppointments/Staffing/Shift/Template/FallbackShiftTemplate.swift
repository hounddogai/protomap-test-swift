import AcmePlatform
import Foundation

extension Staffing {
    /// Where a fallback shift template is in its life cycle.
    enum FallbackShiftTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One fallback shift template, with what the planners need to act on it.
    final class FallbackShiftTemplate {
        var code: String
        var label: String
        var active: Bool
        var ceiling: Double
        var name: String
        var status: FallbackShiftTemplateStatus

        init(code: String, label: String, active: Bool, ceiling: Double, name: String, status: FallbackShiftTemplateStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.ceiling = ceiling
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackShiftTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == FallbackShiftTemplateStatus.reopened || next == FallbackShiftTemplateStatus.archived
            case .inReview:
                return next == FallbackShiftTemplateStatus.resolved || next == FallbackShiftTemplateStatus.archived
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: FallbackShiftTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback shift template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return ceiling
        }

        func copyValue() -> FallbackShiftTemplate {
            return FallbackShiftTemplate(
                code: code,
                label: label,
                active: active,
                ceiling: ceiling,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback shift template in status open.
    static func newFallbackShiftTemplate(_ code: String, label: String) -> FallbackShiftTemplate {
        return FallbackShiftTemplate(
            code: code,
            label: label,
            active: false,
            ceiling: 0.0,
            name: "",
            status: FallbackShiftTemplateStatus.`open`
        )
    }
}
