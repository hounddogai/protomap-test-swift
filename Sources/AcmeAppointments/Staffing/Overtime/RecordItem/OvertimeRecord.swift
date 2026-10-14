import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime record is in its life cycle.
    enum OvertimeRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A overtime record. Its code is unique within a tenant.
    final class OvertimeRecord {
        var code: String
        var name: String
        var endsAt: Int
        var locale: String
        var notes: String
        var procedureCode: String
        var label: String
        var status: OvertimeRecordStatus

        init(code: String, name: String, endsAt: Int, locale: String, notes: String, procedureCode: String, label: String, status: OvertimeRecordStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.locale = locale
            self.notes = notes
            self.procedureCode = procedureCode
            self.label = label
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

        func canMoveTo(_ next: OvertimeRecordStatus) -> Bool {
            switch status {
            case .proposed:
                return next == OvertimeRecordStatus.rejected || next == OvertimeRecordStatus.withdrawn
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == OvertimeRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: OvertimeRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return Double(endsAt)
        }

        func copyValue() -> OvertimeRecord {
            return OvertimeRecord(
                code: code,
                name: name,
                endsAt: endsAt,
                locale: locale,
                notes: notes,
                procedureCode: procedureCode,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a overtime record in status proposed.
    static func newOvertimeRecord(_ code: String, name: String) -> OvertimeRecord {
        return OvertimeRecord(
            code: code,
            name: name,
            endsAt: 0,
            locale: "",
            notes: "",
            procedureCode: "",
            label: "",
            status: OvertimeRecordStatus.proposed
        )
    }
}
