import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a tiered task override is in its life cycle.
    enum TieredTaskOverrideStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One tiered task override, with what the planners need to act on it.
    final class TieredTaskOverride {
        var code: String
        var label: String
        var locale: String
        var expiresAt: Int
        var timezone: String
        var updatedAt: Int
        var bed: String
        var country: String
        var attempts: Int
        var patientRef: String
        var status: TieredTaskOverrideStatus

        init(code: String, label: String, locale: String, expiresAt: Int, timezone: String, updatedAt: Int, bed: String, country: String, attempts: Int, patientRef: String, status: TieredTaskOverrideStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.expiresAt = expiresAt
            self.timezone = timezone
            self.updatedAt = updatedAt
            self.bed = bed
            self.country = country
            self.attempts = attempts
            self.patientRef = patientRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredTaskOverrideStatus) -> Bool {
            switch status {
            case .created:
                return next == TieredTaskOverrideStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: TieredTaskOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered task override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("tiered task override") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(expiresAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TieredTaskOverride {
            return TieredTaskOverride(
                code: code,
                label: label,
                locale: locale,
                expiresAt: expiresAt,
                timezone: timezone,
                updatedAt: updatedAt,
                bed: bed,
                country: country,
                attempts: attempts,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a tiered task override in status created.
    static func newTieredTaskOverride(_ code: String, label: String) -> TieredTaskOverride {
        return TieredTaskOverride(
            code: code,
            label: label,
            locale: "",
            expiresAt: 0,
            timezone: "",
            updatedAt: 0,
            bed: "",
            country: "",
            attempts: 0,
            patientRef: "",
            status: TieredTaskOverrideStatus.created
        )
    }
}
