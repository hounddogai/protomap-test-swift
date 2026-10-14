import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal worklist template is in its life cycle.
    enum SeasonalWorklistTemplateStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A seasonal worklist template as the worklist team keeps it.
    final class SeasonalWorklistTemplate {
        var code: String
        var title: String
        var encounterID: String
        var sequence: Int
        var limit: Int
        var refills: Int
        var status: SeasonalWorklistTemplateStatus

        init(code: String, title: String, encounterID: String, sequence: Int, limit: Int, refills: Int, status: SeasonalWorklistTemplateStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.sequence = sequence
            self.limit = limit
            self.refills = refills
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

        func canMoveTo(_ next: SeasonalWorklistTemplateStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SeasonalWorklistTemplateStatus.archived
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: SeasonalWorklistTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal worklist template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("seasonal worklist template") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(sequence) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalWorklistTemplate {
            return SeasonalWorklistTemplate(
                code: code,
                title: title,
                encounterID: encounterID,
                sequence: sequence,
                limit: limit,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a seasonal worklist template in status open.
    static func newSeasonalWorklistTemplate(_ code: String, title: String) -> SeasonalWorklistTemplate {
        return SeasonalWorklistTemplate(
            code: code,
            title: title,
            encounterID: "",
            sequence: 0,
            limit: 0,
            refills: 0,
            status: SeasonalWorklistTemplateStatus.`open`
        )
    }
}
