import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling slot rollup is in its life cycle.
    enum RollingSlotRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rolling slot rollup, with what the planners need to act on it.
    final class RollingSlotRollup {
        var code: String
        var label: String
        var specialty: String
        var name: String
        var copay: Double
        var priority: Int
        var retries: Int
        var ratio: Double
        var visible: Bool
        var expiresAt: Int
        var bed: String
        var status: RollingSlotRollupStatus

        init(code: String, label: String, specialty: String, name: String, copay: Double, priority: Int, retries: Int, ratio: Double, visible: Bool, expiresAt: Int, bed: String, status: RollingSlotRollupStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.name = name
            self.copay = copay
            self.priority = priority
            self.retries = retries
            self.ratio = ratio
            self.visible = visible
            self.expiresAt = expiresAt
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingSlotRollupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RollingSlotRollupStatus.published || next == RollingSlotRollupStatus.retired
            case .published:
                return next == RollingSlotRollupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingSlotRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling slot rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("rolling slot rollup") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(expiresAt) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> RollingSlotRollup {
            return RollingSlotRollup(
                code: code,
                label: label,
                specialty: specialty,
                name: name,
                copay: copay,
                priority: priority,
                retries: retries,
                ratio: ratio,
                visible: visible,
                expiresAt: expiresAt,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a rolling slot rollup in status created.
    static func newRollingSlotRollup(_ code: String, label: String) -> RollingSlotRollup {
        return RollingSlotRollup(
            code: code,
            label: label,
            specialty: "",
            name: "",
            copay: 0.0,
            priority: 0,
            retries: 0,
            ratio: 0.0,
            visible: false,
            expiresAt: 0,
            bed: "",
            status: RollingSlotRollupStatus.created
        )
    }
}
