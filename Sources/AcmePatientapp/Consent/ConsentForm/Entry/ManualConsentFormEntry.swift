import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual consent form entry is in its life cycle.
    enum ManualConsentFormEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual consent form entry as the consent form team keeps it.
    final class ManualConsentFormEntry {
        var code: String
        var name: String
        var windowDays: Int
        var attempts: Int
        var graceDays: Int
        var acuity: Int
        var allergy: String
        var status: ManualConsentFormEntryStatus

        init(code: String, name: String, windowDays: Int, attempts: Int, graceDays: Int, acuity: Int, allergy: String, status: ManualConsentFormEntryStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.attempts = attempts
            self.graceDays = graceDays
            self.acuity = acuity
            self.allergy = allergy
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

        func canMoveTo(_ next: ManualConsentFormEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualConsentFormEntryStatus.expired
            case .granted:
                return next == ManualConsentFormEntryStatus.revoked || next == ManualConsentFormEntryStatus.expired
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

        func moveTo(_ next: ManualConsentFormEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual consent form entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual consent form entry") \(code)"
        }

        func projectedLoad() -> Double {
            return ((Double(graceDays) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ManualConsentFormEntry {
            return ManualConsentFormEntry(
                code: code,
                name: name,
                windowDays: windowDays,
                attempts: attempts,
                graceDays: graceDays,
                acuity: acuity,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a manual consent form entry in status requested.
    static func newManualConsentFormEntry(_ code: String, name: String) -> ManualConsentFormEntry {
        return ManualConsentFormEntry(
            code: code,
            name: name,
            windowDays: 0,
            attempts: 0,
            graceDays: 0,
            acuity: 0,
            allergy: "",
            status: ManualConsentFormEntryStatus.requested
        )
    }
}
