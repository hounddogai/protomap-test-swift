import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range template is in its life cycle.
    enum ReferenceRangeTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A reference range template as the reference range team keeps it.
    final class ReferenceRangeTemplate {
        var code: String
        var title: String
        var createdAt: Int
        var label: String
        var encounterID: String
        var status: ReferenceRangeTemplateStatus

        init(code: String, title: String, createdAt: Int, label: String, encounterID: String, status: ReferenceRangeTemplateStatus) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.label = label
            self.encounterID = encounterID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ReferenceRangeTemplateStatus.cancelled
            case .inProgress:
                return next == ReferenceRangeTemplateStatus.completed || next == ReferenceRangeTemplateStatus.cancelled
            case .completed:
                return next == ReferenceRangeTemplateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(createdAt)
        }

        func copyValue() -> ReferenceRangeTemplate {
            return ReferenceRangeTemplate(
                code: code,
                title: title,
                createdAt: createdAt,
                label: label,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a reference range template in status planned.
    static func newReferenceRangeTemplate(_ code: String, title: String) -> ReferenceRangeTemplate {
        return ReferenceRangeTemplate(
            code: code,
            title: title,
            createdAt: 0,
            label: "",
            encounterID: "",
            status: ReferenceRangeTemplateStatus.planned
        )
    }
}
