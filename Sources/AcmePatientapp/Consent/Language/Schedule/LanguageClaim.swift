import AcmePlatform
import Foundation

extension Consent {
    /// Where a language claim is in its life cycle.
    enum LanguageClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A language claim as the language team keeps it.
    final class LanguageClaim {
        var code: String
        var label: String
        var durationMinutes: Int
        var allergy: String
        var timezone: String
        var priority: Int
        var approved: Bool
        var notes: String
        var version: Int
        var status: LanguageClaimStatus

        init(code: String, label: String, durationMinutes: Int, allergy: String, timezone: String, priority: Int, approved: Bool, notes: String, version: Int, status: LanguageClaimStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.allergy = allergy
            self.timezone = timezone
            self.priority = priority
            self.approved = approved
            self.notes = notes
            self.version = version
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

        func canMoveTo(_ next: LanguageClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LanguageClaimStatus.rejected || next == LanguageClaimStatus.withdrawn
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

        func moveTo(_ next: LanguageClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func effectiveLoad() -> Double {
            return ((Double(version) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageClaim {
            return LanguageClaim(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                allergy: allergy,
                timezone: timezone,
                priority: priority,
                approved: approved,
                notes: notes,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a language claim in status proposed.
    static func newLanguageClaim(_ code: String, label: String) -> LanguageClaim {
        return LanguageClaim(
            code: code,
            label: label,
            durationMinutes: 0,
            allergy: "",
            timezone: "",
            priority: 0,
            approved: false,
            notes: "",
            version: 0,
            status: LanguageClaimStatus.proposed
        )
    }
}
