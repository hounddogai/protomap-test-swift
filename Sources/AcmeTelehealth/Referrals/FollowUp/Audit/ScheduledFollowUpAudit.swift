import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up audit is in its life cycle.
    enum ScheduledFollowUpAuditStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A scheduled follow up audit as the follow up team keeps it.
    final class ScheduledFollowUpAudit {
        var code: String
        var title: String
        var diagnosisCode: String
        var encounterID: String
        var specialty: String
        var floorValue: Double
        var externalRef: String
        var currency: String
        var status: ScheduledFollowUpAuditStatus

        init(code: String, title: String, diagnosisCode: String, encounterID: String, specialty: String, floorValue: Double, externalRef: String, currency: String, status: ScheduledFollowUpAuditStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.encounterID = encounterID
            self.specialty = specialty
            self.floorValue = floorValue
            self.externalRef = externalRef
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledFollowUpAuditStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ScheduledFollowUpAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled follow up audit") \(code)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> ScheduledFollowUpAudit {
            return ScheduledFollowUpAudit(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                encounterID: encounterID,
                specialty: specialty,
                floorValue: floorValue,
                externalRef: externalRef,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled follow up audit in status proposed.
    static func newScheduledFollowUpAudit(_ code: String, title: String) -> ScheduledFollowUpAudit {
        return ScheduledFollowUpAudit(
            code: code,
            title: title,
            diagnosisCode: "",
            encounterID: "",
            specialty: "",
            floorValue: 0.0,
            externalRef: "",
            currency: "",
            status: ScheduledFollowUpAuditStatus.proposed
        )
    }
}
