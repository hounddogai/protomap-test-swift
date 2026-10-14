import AcmePlatform
import Foundation

extension Consent {
    /// Where a language quota is in its life cycle.
    enum LanguageQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One language quota, with what the planners need to act on it.
    final class LanguageQuota {
        var code: String
        var title: String
        var externalRef: String
        var endsAt: Int
        var dosageMg: Double
        var specialty: String
        var status: LanguageQuotaStatus

        init(code: String, title: String, externalRef: String, endsAt: Int, dosageMg: Double, specialty: String, status: LanguageQuotaStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.endsAt = endsAt
            self.dosageMg = dosageMg
            self.specialty = specialty
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

        func canMoveTo(_ next: LanguageQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LanguageQuotaStatus.rejected
            case .approved:
                return next == LanguageQuotaStatus.withdrawn
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

        func moveTo(_ next: LanguageQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedValue() -> Double {
            return ((dosageMg - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageQuota {
            return LanguageQuota(
                code: code,
                title: title,
                externalRef: externalRef,
                endsAt: endsAt,
                dosageMg: dosageMg,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a language quota in status proposed.
    static func newLanguageQuota(_ code: String, title: String) -> LanguageQuota {
        return LanguageQuota(
            code: code,
            title: title,
            externalRef: "",
            endsAt: 0,
            dosageMg: 0.0,
            specialty: "",
            status: LanguageQuotaStatus.proposed
        )
    }
}
