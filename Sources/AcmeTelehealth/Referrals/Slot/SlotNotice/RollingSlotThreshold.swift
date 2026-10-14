import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling slot threshold is in its life cycle.
    enum RollingSlotThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A rolling slot threshold. Its code is unique within a tenant.
    final class RollingSlotThreshold {
        var code: String
        var title: String
        var maximum: Double
        var ratio: Double
        var floorValue: Double
        var createdAt: Int
        var revision: Int
        var graceDays: Int
        var reviewer: String
        var acuity: Int
        var capacity: Int
        var status: RollingSlotThresholdStatus

        init(code: String, title: String, maximum: Double, ratio: Double, floorValue: Double, createdAt: Int, revision: Int, graceDays: Int, reviewer: String, acuity: Int, capacity: Int, status: RollingSlotThresholdStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.ratio = ratio
            self.floorValue = floorValue
            self.createdAt = createdAt
            self.revision = revision
            self.graceDays = graceDays
            self.reviewer = reviewer
            self.acuity = acuity
            self.capacity = capacity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingSlotThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == RollingSlotThresholdStatus.active || next == RollingSlotThresholdStatus.suspended
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RollingSlotThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingSlotThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling slot threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netVolume() -> Double {
            return ((maximum + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> RollingSlotThreshold {
            return RollingSlotThreshold(
                code: code,
                title: title,
                maximum: maximum,
                ratio: ratio,
                floorValue: floorValue,
                createdAt: createdAt,
                revision: revision,
                graceDays: graceDays,
                reviewer: reviewer,
                acuity: acuity,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling slot threshold in status draft.
    static func newRollingSlotThreshold(_ code: String, title: String) -> RollingSlotThreshold {
        return RollingSlotThreshold(
            code: code,
            title: title,
            maximum: 0.0,
            ratio: 0.0,
            floorValue: 0.0,
            createdAt: 0,
            revision: 0,
            graceDays: 0,
            reviewer: "",
            acuity: 0,
            capacity: 0,
            status: RollingSlotThresholdStatus.draft
        )
    }
}
