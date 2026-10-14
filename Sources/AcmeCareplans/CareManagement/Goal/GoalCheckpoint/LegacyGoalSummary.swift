import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy goal summary is in its life cycle.
    enum LegacyGoalSummaryStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy goal summary and its current status.
    final class LegacyGoalSummary {
        var code: String
        var title: String
        var cost: Double
        var encounterID: String
        var priority: Int
        var patientRef: String
        var retries: Int
        var status: LegacyGoalSummaryStatus

        init(code: String, title: String, cost: Double, encounterID: String, priority: Int, patientRef: String, retries: Int, status: LegacyGoalSummaryStatus) {
            self.code = code
            self.title = title
            self.cost = cost
            self.encounterID = encounterID
            self.priority = priority
            self.patientRef = patientRef
            self.retries = retries
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

        func canMoveTo(_ next: LegacyGoalSummaryStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
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
                return next == LegacyGoalSummaryStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyGoalSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy goal summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return ((Double(retries) - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LegacyGoalSummary {
            return LegacyGoalSummary(
                code: code,
                title: title,
                cost: cost,
                encounterID: encounterID,
                priority: priority,
                patientRef: patientRef,
                retries: retries,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy goal summary in status open.
    static func newLegacyGoalSummary(_ code: String, title: String) -> LegacyGoalSummary {
        return LegacyGoalSummary(
            code: code,
            title: title,
            cost: 0.0,
            encounterID: "",
            priority: 0,
            patientRef: "",
            retries: 0,
            status: LegacyGoalSummaryStatus.`open`
        )
    }
}
