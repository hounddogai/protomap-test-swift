import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy authorization snapshot is in its life cycle.
    enum LegacyAuthorizationSnapshotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy authorization snapshot as the authorization team keeps it.
    final class LegacyAuthorizationSnapshot {
        var code: String
        var label: String
        var maximum: Double
        var refills: Int
        var threshold: Double
        var durationMinutes: Int
        var locale: String
        var status: LegacyAuthorizationSnapshotStatus

        init(code: String, label: String, maximum: Double, refills: Int, threshold: Double, durationMinutes: Int, locale: String, status: LegacyAuthorizationSnapshotStatus) {
            self.code = code
            self.label = label
            self.maximum = maximum
            self.refills = refills
            self.threshold = threshold
            self.durationMinutes = durationMinutes
            self.locale = locale
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

        func canMoveTo(_ next: LegacyAuthorizationSnapshotStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyAuthorizationSnapshotStatus.completed
            case .scheduled:
                return next == LegacyAuthorizationSnapshotStatus.completed || next == LegacyAuthorizationSnapshotStatus.cancelled
            case .inProgress:
                return next == LegacyAuthorizationSnapshotStatus.completed || next == LegacyAuthorizationSnapshotStatus.cancelled
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

        func moveTo(_ next: LegacyAuthorizationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy authorization snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("legacy authorization snapshot") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(durationMinutes) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAuthorizationSnapshot {
            return LegacyAuthorizationSnapshot(
                code: code,
                label: label,
                maximum: maximum,
                refills: refills,
                threshold: threshold,
                durationMinutes: durationMinutes,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a legacy authorization snapshot in status planned.
    static func newLegacyAuthorizationSnapshot(_ code: String, label: String) -> LegacyAuthorizationSnapshot {
        return LegacyAuthorizationSnapshot(
            code: code,
            label: label,
            maximum: 0.0,
            refills: 0,
            threshold: 0.0,
            durationMinutes: 0,
            locale: "",
            status: LegacyAuthorizationSnapshotStatus.planned
        )
    }
}
