import AcmePlatform
import Foundation

extension Staffing {
    /// Where a scheduled shift template is in its life cycle.
    enum ScheduledShiftTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One scheduled shift template, with what the planners need to act on it.
    final class ScheduledShiftTemplate {
        var code: String
        var name: String
        var channel: String
        var pinned: Bool
        var procedureCode: String
        var clinicianID: String
        var summary: String
        var contactEmail: String
        var specialty: String
        var quantity: Int
        var status: ScheduledShiftTemplateStatus

        init(code: String, name: String, channel: String, pinned: Bool, procedureCode: String, clinicianID: String, summary: String, contactEmail: String, specialty: String, quantity: Int, status: ScheduledShiftTemplateStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.pinned = pinned
            self.procedureCode = procedureCode
            self.clinicianID = clinicianID
            self.summary = summary
            self.contactEmail = contactEmail
            self.specialty = specialty
            self.quantity = quantity
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

        func canMoveTo(_ next: ScheduledShiftTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == ScheduledShiftTemplateStatus.rejected
            case .rejected:
                return next == ScheduledShiftTemplateStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledShiftTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled shift template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ScheduledShiftTemplate {
            return ScheduledShiftTemplate(
                code: code,
                name: name,
                channel: channel,
                pinned: pinned,
                procedureCode: procedureCode,
                clinicianID: clinicianID,
                summary: summary,
                contactEmail: contactEmail,
                specialty: specialty,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a scheduled shift template in status proposed.
    static func newScheduledShiftTemplate(_ code: String, name: String) -> ScheduledShiftTemplate {
        return ScheduledShiftTemplate(
            code: code,
            name: name,
            channel: "",
            pinned: false,
            procedureCode: "",
            clinicianID: "",
            summary: "",
            contactEmail: "",
            specialty: "",
            quantity: 0,
            status: ScheduledShiftTemplateStatus.proposed
        )
    }
}
