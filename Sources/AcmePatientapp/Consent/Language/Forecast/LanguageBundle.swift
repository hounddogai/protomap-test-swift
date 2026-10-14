import AcmePlatform
import Foundation

extension Consent {
    /// Where a language bundle is in its life cycle.
    enum LanguageBundleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One language bundle, with what the planners need to act on it.
    final class LanguageBundle {
        var code: String
        var name: String
        var pinned: Bool
        var attempts: Int
        var windowDays: Int
        var floorValue: Double
        var phone: String
        var startsAt: Int
        var clinicianID: String
        var dosageMg: Double
        var status: LanguageBundleStatus

        init(code: String, name: String, pinned: Bool, attempts: Int, windowDays: Int, floorValue: Double, phone: String, startsAt: Int, clinicianID: String, dosageMg: Double, status: LanguageBundleStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.attempts = attempts
            self.windowDays = windowDays
            self.floorValue = floorValue
            self.phone = phone
            self.startsAt = startsAt
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: LanguageBundleStatus) -> Bool {
            switch status {
            case .planned:
                return next == LanguageBundleStatus.scheduled || next == LanguageBundleStatus.cancelled
            case .scheduled:
                return next == LanguageBundleStatus.inProgress || next == LanguageBundleStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
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

        func moveTo(_ next: LanguageBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("language bundle") \(code)"
        }

        func netVolume() -> Double {
            return ((Double(attempts) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> LanguageBundle {
            return LanguageBundle(
                code: code,
                name: name,
                pinned: pinned,
                attempts: attempts,
                windowDays: windowDays,
                floorValue: floorValue,
                phone: phone,
                startsAt: startsAt,
                clinicianID: clinicianID,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a language bundle in status planned.
    static func newLanguageBundle(_ code: String, name: String) -> LanguageBundle {
        return LanguageBundle(
            code: code,
            name: name,
            pinned: false,
            attempts: 0,
            windowDays: 0,
            floorValue: 0.0,
            phone: "",
            startsAt: 0,
            clinicianID: "",
            dosageMg: 0.0,
            status: LanguageBundleStatus.planned
        )
    }
}
