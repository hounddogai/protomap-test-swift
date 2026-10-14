import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling charge segment is in its life cycle.
    enum RollingChargeSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One rolling charge segment, with what the planners need to act on it.
    final class RollingChargeSegment {
        var code: String
        var name: String
        var capacity: Int
        var revision: Int
        var score: Double
        var unit: String
        var status: RollingChargeSegmentStatus

        init(code: String, name: String, capacity: Int, revision: Int, score: Double, unit: String, status: RollingChargeSegmentStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.revision = revision
            self.score = score
            self.unit = unit
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

        func canMoveTo(_ next: RollingChargeSegmentStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingChargeSegmentStatus.retired
            case .validated:
                return next == RollingChargeSegmentStatus.published || next == RollingChargeSegmentStatus.retired
            case .published:
                return next == RollingChargeSegmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingChargeSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling charge segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedLoad() -> Double {
            return ((Double(revision) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> RollingChargeSegment {
            return RollingChargeSegment(
                code: code,
                name: name,
                capacity: capacity,
                revision: revision,
                score: score,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a rolling charge segment in status created.
    static func newRollingChargeSegment(_ code: String, name: String) -> RollingChargeSegment {
        return RollingChargeSegment(
            code: code,
            name: name,
            capacity: 0,
            revision: 0,
            score: 0.0,
            unit: "",
            status: RollingChargeSegmentStatus.created
        )
    }
}
