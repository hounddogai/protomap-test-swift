import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary schedule is in its life cycle.
    enum FormularyScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A formulary schedule. Its code is unique within a tenant.
    final class FormularySchedule {
        var code: String
        var name: String
        var channel: String
        var bed: String
        var allergy: String
        var encounterID: String
        var quantity: Int
        var status: FormularyScheduleStatus

        init(code: String, name: String, channel: String, bed: String, allergy: String, encounterID: String, quantity: Int, status: FormularyScheduleStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.bed = bed
            self.allergy = allergy
            self.encounterID = encounterID
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

        func canMoveTo(_ next: FormularyScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FormularyScheduleStatus.approved
            case .approved:
                return next == FormularyScheduleStatus.rejected || next == FormularyScheduleStatus.withdrawn
            case .rejected:
                return next == FormularyScheduleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> FormularySchedule {
            return FormularySchedule(
                code: code,
                name: name,
                channel: channel,
                bed: bed,
                allergy: allergy,
                encounterID: encounterID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a formulary schedule in status proposed.
    static func newFormularySchedule(_ code: String, name: String) -> FormularySchedule {
        return FormularySchedule(
            code: code,
            name: name,
            channel: "",
            bed: "",
            allergy: "",
            encounterID: "",
            quantity: 0,
            status: FormularyScheduleStatus.proposed
        )
    }
}
