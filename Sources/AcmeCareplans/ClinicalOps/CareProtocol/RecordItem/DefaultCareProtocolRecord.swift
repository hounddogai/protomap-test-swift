import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default care protocol record is in its life cycle.
    enum DefaultCareProtocolRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A default care protocol record. Its code is unique within a tenant.
    final class DefaultCareProtocolRecord {
        var code: String
        var title: String
        var sequence: Int
        var procedureCode: String
        var unit: String
        var clinicianID: String
        var locale: String
        var graceDays: Int
        var status: DefaultCareProtocolRecordStatus

        init(code: String, title: String, sequence: Int, procedureCode: String, unit: String, clinicianID: String, locale: String, graceDays: Int, status: DefaultCareProtocolRecordStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.procedureCode = procedureCode
            self.unit = unit
            self.clinicianID = clinicianID
            self.locale = locale
            self.graceDays = graceDays
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

        func canMoveTo(_ next: DefaultCareProtocolRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: DefaultCareProtocolRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default care protocol record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveLoad() -> Double {
            return ((Double(sequence) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultCareProtocolRecord {
            return DefaultCareProtocolRecord(
                code: code,
                title: title,
                sequence: sequence,
                procedureCode: procedureCode,
                unit: unit,
                clinicianID: clinicianID,
                locale: locale,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a default care protocol record in status proposed.
    static func newDefaultCareProtocolRecord(_ code: String, title: String) -> DefaultCareProtocolRecord {
        return DefaultCareProtocolRecord(
            code: code,
            title: title,
            sequence: 0,
            procedureCode: "",
            unit: "",
            clinicianID: "",
            locale: "",
            graceDays: 0,
            status: DefaultCareProtocolRecordStatus.proposed
        )
    }
}
