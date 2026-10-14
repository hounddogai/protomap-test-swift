import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled study rule is in its life cycle.
    enum ScheduledStudyRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a scheduled study rule and its current status.
    final class ScheduledStudyRule {
        var code: String
        var title: String
        var facility: String
        var acuity: Int
        var channel: String
        var name: String
        var status: ScheduledStudyRuleStatus

        init(code: String, title: String, facility: String, acuity: Int, channel: String, name: String, status: ScheduledStudyRuleStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.acuity = acuity
            self.channel = channel
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

        func canMoveTo(_ next: ScheduledStudyRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
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
                return next == ScheduledStudyRuleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledStudyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled study rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled study rule") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> ScheduledStudyRule {
            return ScheduledStudyRule(
                code: code,
                title: title,
                facility: facility,
                acuity: acuity,
                channel: channel,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a scheduled study rule in status open.
    static func newScheduledStudyRule(_ code: String, title: String) -> ScheduledStudyRule {
        return ScheduledStudyRule(
            code: code,
            title: title,
            facility: "",
            acuity: 0,
            channel: "",
            name: "",
            status: ScheduledStudyRuleStatus.`open`
        )
    }
}
