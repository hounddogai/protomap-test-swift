import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift preference is in its life cycle.
    enum ShiftPreferenceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A shift preference as the shift team keeps it.
    final class ShiftPreference {
        var code: String
        var label: String
        var facility: String
        var attempts: Int
        var title: String
        var score: Double
        var retries: Int
        var version: Int
        var status: ShiftPreferenceStatus

        init(code: String, label: String, facility: String, attempts: Int, title: String, score: Double, retries: Int, version: Int, status: ShiftPreferenceStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.attempts = attempts
            self.title = title
            self.score = score
            self.retries = retries
            self.version = version
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

        func canMoveTo(_ next: ShiftPreferenceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ShiftPreferenceStatus.expired
            case .revoked:
                return next == ShiftPreferenceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return ((score - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftPreference {
            return ShiftPreference(
                code: code,
                label: label,
                facility: facility,
                attempts: attempts,
                title: title,
                score: score,
                retries: retries,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a shift preference in status requested.
    static func newShiftPreference(_ code: String, label: String) -> ShiftPreference {
        return ShiftPreference(
            code: code,
            label: label,
            facility: "",
            attempts: 0,
            title: "",
            score: 0.0,
            retries: 0,
            version: 0,
            status: ShiftPreferenceStatus.requested
        )
    }
}
