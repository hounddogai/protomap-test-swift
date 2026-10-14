import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled outreach agreement is in its life cycle.
    enum ScheduledOutreachAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One scheduled outreach agreement, with what the planners need to act on it.
    final class ScheduledOutreachAgreement {
        var code: String
        var title: String
        var floorValue: Double
        var margin: Double
        var ownerID: String
        var status: ScheduledOutreachAgreementStatus

        init(code: String, title: String, floorValue: Double, margin: Double, ownerID: String, status: ScheduledOutreachAgreementStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.margin = margin
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ScheduledOutreachAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledOutreachAgreementStatus.resolved
            case .inReview:
                switch next {
                case .archived:
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
                return next == ScheduledOutreachAgreementStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledOutreachAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled outreach agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled outreach agreement") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((margin + floorValue) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledOutreachAgreement {
            return ScheduledOutreachAgreement(
                code: code,
                title: title,
                floorValue: floorValue,
                margin: margin,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled outreach agreement in status open.
    static func newScheduledOutreachAgreement(_ code: String, title: String) -> ScheduledOutreachAgreement {
        return ScheduledOutreachAgreement(
            code: code,
            title: title,
            floorValue: 0.0,
            margin: 0.0,
            ownerID: "",
            status: ScheduledOutreachAgreementStatus.`open`
        )
    }
}
