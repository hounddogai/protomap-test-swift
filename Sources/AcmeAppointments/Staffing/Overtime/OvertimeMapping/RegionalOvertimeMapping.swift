import AcmePlatform
import Foundation

extension Staffing {
    /// Where a regional overtime mapping is in its life cycle.
    enum RegionalOvertimeMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional overtime mapping as the overtime team keeps it.
    final class RegionalOvertimeMapping {
        var code: String
        var name: String
        var procedureCode: String
        var copay: Double
        var clinicianID: String
        var specialty: String
        var channel: String
        var timezone: String
        var status: RegionalOvertimeMappingStatus

        init(code: String, name: String, procedureCode: String, copay: Double, clinicianID: String, specialty: String, channel: String, timezone: String, status: RegionalOvertimeMappingStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.copay = copay
            self.clinicianID = clinicianID
            self.specialty = specialty
            self.channel = channel
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalOvertimeMappingStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: RegionalOvertimeMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional overtime mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func measuredValue() -> Double {
            return copay
        }

        func copyValue() -> RegionalOvertimeMapping {
            return RegionalOvertimeMapping(
                code: code,
                name: name,
                procedureCode: procedureCode,
                copay: copay,
                clinicianID: clinicianID,
                specialty: specialty,
                channel: channel,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a regional overtime mapping in status draft.
    static func newRegionalOvertimeMapping(_ code: String, name: String) -> RegionalOvertimeMapping {
        return RegionalOvertimeMapping(
            code: code,
            name: name,
            procedureCode: "",
            copay: 0.0,
            clinicianID: "",
            specialty: "",
            channel: "",
            timezone: "",
            status: RegionalOvertimeMappingStatus.draft
        )
    }
}
