import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal recall template is in its life cycle.
    enum SeasonalRecallTemplateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a seasonal recall template and its current status.
    final class SeasonalRecallTemplate {
        var code: String
        var title: String
        var dosageMg: Double
        var ownerID: String
        var description: String
        var segment: String
        var status: SeasonalRecallTemplateStatus

        init(code: String, title: String, dosageMg: Double, ownerID: String, description: String, segment: String, status: SeasonalRecallTemplateStatus) {
            self.code = code
            self.title = title
            self.dosageMg = dosageMg
            self.ownerID = ownerID
            self.description = description
            self.segment = segment
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

        func canMoveTo(_ next: SeasonalRecallTemplateStatus) -> Bool {
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
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalRecallTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal recall template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> SeasonalRecallTemplate {
            return SeasonalRecallTemplate(
                code: code,
                title: title,
                dosageMg: dosageMg,
                ownerID: ownerID,
                description: description,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a seasonal recall template in status planned.
    static func newSeasonalRecallTemplate(_ code: String, title: String) -> SeasonalRecallTemplate {
        return SeasonalRecallTemplate(
            code: code,
            title: title,
            dosageMg: 0.0,
            ownerID: "",
            description: "",
            segment: "",
            status: SeasonalRecallTemplateStatus.planned
        )
    }
}
