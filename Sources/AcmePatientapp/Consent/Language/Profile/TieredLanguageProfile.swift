import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered language profile is in its life cycle.
    enum TieredLanguageProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered language profile as the language team keeps it.
    final class TieredLanguageProfile {
        var code: String
        var title: String
        var acuity: Int
        var copay: Double
        var pinned: Bool
        var specialty: String
        var retries: Int
        var attributes: [String: String]
        var status: TieredLanguageProfileStatus

        init(code: String, title: String, acuity: Int, copay: Double, pinned: Bool, specialty: String, retries: Int, attributes: [String: String], status: TieredLanguageProfileStatus) {
            self.code = code
            self.title = title
            self.acuity = acuity
            self.copay = copay
            self.pinned = pinned
            self.specialty = specialty
            self.retries = retries
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredLanguageProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredLanguageProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered language profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveExposure() -> Double {
            return (Double(acuity) * copay * 100).rounded() / 100
        }

        func copyValue() -> TieredLanguageProfile {
            return TieredLanguageProfile(
                code: code,
                title: title,
                acuity: acuity,
                copay: copay,
                pinned: pinned,
                specialty: specialty,
                retries: retries,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered language profile in status planned.
    static func newTieredLanguageProfile(_ code: String, title: String) -> TieredLanguageProfile {
        return TieredLanguageProfile(
            code: code,
            title: title,
            acuity: 0,
            copay: 0.0,
            pinned: false,
            specialty: "",
            retries: 0,
            attributes: [:],
            status: TieredLanguageProfileStatus.planned
        )
    }
}
