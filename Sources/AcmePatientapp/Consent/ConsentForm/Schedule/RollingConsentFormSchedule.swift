import AcmePlatform
import Foundation

extension Consent {
    /// Where a rolling consent form schedule is in its life cycle.
    enum RollingConsentFormScheduleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One rolling consent form schedule, with what the planners need to act on it.
    final class RollingConsentFormSchedule {
        var code: String
        var label: String
        var ward: String
        var country: String
        var clinicianID: String
        var updatedAt: Int
        var status: RollingConsentFormScheduleStatus

        init(code: String, label: String, ward: String, country: String, clinicianID: String, updatedAt: Int, status: RollingConsentFormScheduleStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.country = country
            self.clinicianID = clinicianID
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: RollingConsentFormScheduleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RollingConsentFormScheduleStatus.rejected || next == RollingConsentFormScheduleStatus.withdrawn
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

        func moveTo(_ next: RollingConsentFormScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling consent form schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> RollingConsentFormSchedule {
            return RollingConsentFormSchedule(
                code: code,
                label: label,
                ward: ward,
                country: country,
                clinicianID: clinicianID,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling consent form schedule in status proposed.
    static func newRollingConsentFormSchedule(_ code: String, label: String) -> RollingConsentFormSchedule {
        return RollingConsentFormSchedule(
            code: code,
            label: label,
            ward: "",
            country: "",
            clinicianID: "",
            updatedAt: 0,
            status: RollingConsentFormScheduleStatus.proposed
        )
    }
}
