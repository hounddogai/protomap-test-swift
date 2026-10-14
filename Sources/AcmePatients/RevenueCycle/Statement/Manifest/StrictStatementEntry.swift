import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict statement entry is in its life cycle.
    enum StrictStatementEntryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One strict statement entry, with what the planners need to act on it.
    final class StrictStatementEntry {
        var code: String
        var label: String
        var active: Bool
        var threshold: Double
        var description: String
        var ward: String
        var patientRef: String
        var timezone: String
        var windowDays: Int
        var attempts: Int
        var status: StrictStatementEntryStatus

        init(code: String, label: String, active: Bool, threshold: Double, description: String, ward: String, patientRef: String, timezone: String, windowDays: Int, attempts: Int, status: StrictStatementEntryStatus) {
            self.code = code
            self.label = label
            self.active = active
            self.threshold = threshold
            self.description = description
            self.ward = ward
            self.patientRef = patientRef
            self.timezone = timezone
            self.windowDays = windowDays
            self.attempts = attempts
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

        func canMoveTo(_ next: StrictStatementEntryStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictStatementEntryStatus.granted
            case .granted:
                return next == StrictStatementEntryStatus.expired
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

        func moveTo(_ next: StrictStatementEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict statement entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("strict statement entry") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(attempts) + Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> StrictStatementEntry {
            return StrictStatementEntry(
                code: code,
                label: label,
                active: active,
                threshold: threshold,
                description: description,
                ward: ward,
                patientRef: patientRef,
                timezone: timezone,
                windowDays: windowDays,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a strict statement entry in status requested.
    static func newStrictStatementEntry(_ code: String, label: String) -> StrictStatementEntry {
        return StrictStatementEntry(
            code: code,
            label: label,
            active: false,
            threshold: 0.0,
            description: "",
            ward: "",
            patientRef: "",
            timezone: "",
            windowDays: 0,
            attempts: 0,
            status: StrictStatementEntryStatus.requested
        )
    }
}
