import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled program exception is in its life cycle.
    enum ScheduledProgramExceptionStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A scheduled program exception as the program team keeps it.
    final class ScheduledProgramException {
        var code: String
        var label: String
        var copay: Double
        var createdAt: Int
        var locale: String
        var ward: String
        var specialty: String
        var status: ScheduledProgramExceptionStatus

        init(code: String, label: String, copay: Double, createdAt: Int, locale: String, ward: String, specialty: String, status: ScheduledProgramExceptionStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.createdAt = createdAt
            self.locale = locale
            self.ward = ward
            self.specialty = specialty
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

        func canMoveTo(_ next: ScheduledProgramExceptionStatus) -> Bool {
            switch status {
            case .requested:
                return next == ScheduledProgramExceptionStatus.granted
            case .granted:
                return next == ScheduledProgramExceptionStatus.revoked || next == ScheduledProgramExceptionStatus.expired
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: ScheduledProgramExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled program exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedTotal() -> Double {
            return ((Double(createdAt) - copay) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledProgramException {
            return ScheduledProgramException(
                code: code,
                label: label,
                copay: copay,
                createdAt: createdAt,
                locale: locale,
                ward: ward,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a scheduled program exception in status requested.
    static func newScheduledProgramException(_ code: String, label: String) -> ScheduledProgramException {
        return ScheduledProgramException(
            code: code,
            label: label,
            copay: 0.0,
            createdAt: 0,
            locale: "",
            ward: "",
            specialty: "",
            status: ScheduledProgramExceptionStatus.requested
        )
    }
}
