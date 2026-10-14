import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched overtime rollup is in its life cycle.
    enum BatchedOvertimeRollupStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A batched overtime rollup. Its code is unique within a tenant.
    final class BatchedOvertimeRollup {
        var code: String
        var label: String
        var priority: Int
        var ratio: Double
        var startsAt: Int
        var ward: String
        var summary: String
        var endsAt: Int
        var status: BatchedOvertimeRollupStatus

        init(code: String, label: String, priority: Int, ratio: Double, startsAt: Int, ward: String, summary: String, endsAt: Int, status: BatchedOvertimeRollupStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.ratio = ratio
            self.startsAt = startsAt
            self.ward = ward
            self.summary = summary
            self.endsAt = endsAt
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

        func canMoveTo(_ next: BatchedOvertimeRollupStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == BatchedOvertimeRollupStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: BatchedOvertimeRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched overtime rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("batched overtime rollup") \(code)"
        }

        func projectedVolume() -> Double {
            return ((ratio + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOvertimeRollup {
            return BatchedOvertimeRollup(
                code: code,
                label: label,
                priority: priority,
                ratio: ratio,
                startsAt: startsAt,
                ward: ward,
                summary: summary,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a batched overtime rollup in status idle.
    static func newBatchedOvertimeRollup(_ code: String, label: String) -> BatchedOvertimeRollup {
        return BatchedOvertimeRollup(
            code: code,
            label: label,
            priority: 0,
            ratio: 0.0,
            startsAt: 0,
            ward: "",
            summary: "",
            endsAt: 0,
            status: BatchedOvertimeRollupStatus.idle
        )
    }
}
