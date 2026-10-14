import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict care protocol template is in its life cycle.
    enum StrictCareProtocolTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One strict care protocol template, with what the planners need to act on it.
    final class StrictCareProtocolTemplate {
        var code: String
        var label: String
        var approved: Bool
        var copay: Double
        var dosageMg: Double
        var summary: String
        var capacity: Int
        var description: String
        var ratio: Double
        var status: StrictCareProtocolTemplateStatus

        init(code: String, label: String, approved: Bool, copay: Double, dosageMg: Double, summary: String, capacity: Int, description: String, ratio: Double, status: StrictCareProtocolTemplateStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.copay = copay
            self.dosageMg = dosageMg
            self.summary = summary
            self.capacity = capacity
            self.description = description
            self.ratio = ratio
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

        func canMoveTo(_ next: StrictCareProtocolTemplateStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == StrictCareProtocolTemplateStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: StrictCareProtocolTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict care protocol template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return ((copay - ratio) * 100).rounded() / 100
        }

        func copyValue() -> StrictCareProtocolTemplate {
            return StrictCareProtocolTemplate(
                code: code,
                label: label,
                approved: approved,
                copay: copay,
                dosageMg: dosageMg,
                summary: summary,
                capacity: capacity,
                description: description,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict care protocol template in status planned.
    static func newStrictCareProtocolTemplate(_ code: String, label: String) -> StrictCareProtocolTemplate {
        return StrictCareProtocolTemplate(
            code: code,
            label: label,
            approved: false,
            copay: 0.0,
            dosageMg: 0.0,
            summary: "",
            capacity: 0,
            description: "",
            ratio: 0.0,
            status: StrictCareProtocolTemplateStatus.planned
        )
    }
}
