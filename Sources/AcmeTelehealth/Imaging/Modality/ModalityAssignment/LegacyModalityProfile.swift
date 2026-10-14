import AcmePlatform
import Foundation

extension Imaging {
    /// Where a legacy modality profile is in its life cycle.
    enum LegacyModalityProfileStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy modality profile as the modality team keeps it.
    final class LegacyModalityProfile {
        var code: String
        var name: String
        var specialty: String
        var windowDays: Int
        var externalRef: String
        var status: LegacyModalityProfileStatus

        init(code: String, name: String, specialty: String, windowDays: Int, externalRef: String, status: LegacyModalityProfileStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.windowDays = windowDays
            self.externalRef = externalRef
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyModalityProfileStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == LegacyModalityProfileStatus.ready
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LegacyModalityProfileStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyModalityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy modality profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy modality profile") \(code)"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> LegacyModalityProfile {
            return LegacyModalityProfile(
                code: code,
                name: name,
                specialty: specialty,
                windowDays: windowDays,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy modality profile in status idle.
    static func newLegacyModalityProfile(_ code: String, name: String) -> LegacyModalityProfile {
        return LegacyModalityProfile(
            code: code,
            name: name,
            specialty: "",
            windowDays: 0,
            externalRef: "",
            status: LegacyModalityProfileStatus.idle
        )
    }
}
