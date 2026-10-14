import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a legacy program notice is in its life cycle.
    enum LegacyProgramNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One legacy program notice, with what the planners need to act on it.
    final class LegacyProgramNotice {
        var code: String
        var label: String
        var capacity: Int
        var minimum: Double
        var durationMinutes: Int
        var status: LegacyProgramNoticeStatus

        init(code: String, label: String, capacity: Int, minimum: Double, durationMinutes: Int, status: LegacyProgramNoticeStatus) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.minimum = minimum
            self.durationMinutes = durationMinutes
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

        func canMoveTo(_ next: LegacyProgramNoticeStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == LegacyProgramNoticeStatus.expired
            case .revoked:
                return next == LegacyProgramNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyProgramNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy program notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return (minimum * Double(capacity) * 100).rounded() / 100
        }

        func copyValue() -> LegacyProgramNotice {
            return LegacyProgramNotice(
                code: code,
                label: label,
                capacity: capacity,
                minimum: minimum,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a legacy program notice in status requested.
    static func newLegacyProgramNotice(_ code: String, label: String) -> LegacyProgramNotice {
        return LegacyProgramNotice(
            code: code,
            label: label,
            capacity: 0,
            minimum: 0.0,
            durationMinutes: 0,
            status: LegacyProgramNoticeStatus.requested
        )
    }
}
