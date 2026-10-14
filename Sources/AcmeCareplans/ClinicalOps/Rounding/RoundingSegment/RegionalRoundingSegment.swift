import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional rounding segment is in its life cycle.
    enum RegionalRoundingSegmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional rounding segment as the rounding team keeps it.
    final class RegionalRoundingSegment {
        var code: String
        var name: String
        var limit: Int
        var priority: Int
        var graceDays: Int
        var attempts: Int
        var pinned: Bool
        var status: RegionalRoundingSegmentStatus

        init(code: String, name: String, limit: Int, priority: Int, graceDays: Int, attempts: Int, pinned: Bool, status: RegionalRoundingSegmentStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.priority = priority
            self.graceDays = graceDays
            self.attempts = attempts
            self.pinned = pinned
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

        func canMoveTo(_ next: RegionalRoundingSegmentStatus) -> Bool {
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
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalRoundingSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional rounding segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional rounding segment") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(priority) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRoundingSegment {
            return RegionalRoundingSegment(
                code: code,
                name: name,
                limit: limit,
                priority: priority,
                graceDays: graceDays,
                attempts: attempts,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional rounding segment in status created.
    static func newRegionalRoundingSegment(_ code: String, name: String) -> RegionalRoundingSegment {
        return RegionalRoundingSegment(
            code: code,
            name: name,
            limit: 0,
            priority: 0,
            graceDays: 0,
            attempts: 0,
            pinned: false,
            status: RegionalRoundingSegmentStatus.created
        )
    }
}
