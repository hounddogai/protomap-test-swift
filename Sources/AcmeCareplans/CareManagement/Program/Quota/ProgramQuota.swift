import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a program quota is in its life cycle.
    enum ProgramQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a program quota and its current status.
    final class ProgramQuota {
        var code: String
        var name: String
        var copay: Double
        var encounterID: String
        var locale: String
        var graceDays: Int
        var status: ProgramQuotaStatus

        init(code: String, name: String, copay: Double, encounterID: String, locale: String, graceDays: Int, status: ProgramQuotaStatus) {
            self.code = code
            self.name = name
            self.copay = copay
            self.encounterID = encounterID
            self.locale = locale
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ProgramQuotaStatus) -> Bool {
            switch status {
            case .requested:
                return next == ProgramQuotaStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ProgramQuotaStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProgramQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("program quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return (Double(graceDays) * copay * 100).rounded() / 100
        }

        func copyValue() -> ProgramQuota {
            return ProgramQuota(
                code: code,
                name: name,
                copay: copay,
                encounterID: encounterID,
                locale: locale,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a program quota in status requested.
    static func newProgramQuota(_ code: String, name: String) -> ProgramQuota {
        return ProgramQuota(
            code: code,
            name: name,
            copay: 0.0,
            encounterID: "",
            locale: "",
            graceDays: 0,
            status: ProgramQuotaStatus.requested
        )
    }
}
