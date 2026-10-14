import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a legacy charge batch is in its life cycle.
    enum LegacyChargeBatchStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A legacy charge batch as the charge team keeps it.
    final class LegacyChargeBatch {
        var code: String
        var name: String
        var timezone: String
        var startsAt: Int
        var ratio: Double
        var region: String
        var status: LegacyChargeBatchStatus

        init(code: String, name: String, timezone: String, startsAt: Int, ratio: Double, region: String, status: LegacyChargeBatchStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.startsAt = startsAt
            self.ratio = ratio
            self.region = region
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

        func canMoveTo(_ next: LegacyChargeBatchStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyChargeBatchStatus.scheduled || next == LegacyChargeBatchStatus.completed
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == LegacyChargeBatchStatus.completed || next == LegacyChargeBatchStatus.cancelled
            case .completed:
                return next == LegacyChargeBatchStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyChargeBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy charge batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return (Double(startsAt) * ratio * 100).rounded() / 100
        }

        func copyValue() -> LegacyChargeBatch {
            return LegacyChargeBatch(
                code: code,
                name: name,
                timezone: timezone,
                startsAt: startsAt,
                ratio: ratio,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a legacy charge batch in status planned.
    static func newLegacyChargeBatch(_ code: String, name: String) -> LegacyChargeBatch {
        return LegacyChargeBatch(
            code: code,
            name: name,
            timezone: "",
            startsAt: 0,
            ratio: 0.0,
            region: "",
            status: LegacyChargeBatchStatus.planned
        )
    }
}
