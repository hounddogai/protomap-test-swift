import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched overtime plan is in its life cycle.
    enum BatchedOvertimePlanStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One batched overtime plan, with what the planners need to act on it.
    final class BatchedOvertimePlan {
        var code: String
        var name: String
        var patientRef: String
        var threshold: Double
        var tags: [String]
        var rate: Double
        var segment: String
        var attempts: Int
        var region: String
        var ceiling: Double
        var status: BatchedOvertimePlanStatus

        init(code: String, name: String, patientRef: String, threshold: Double, tags: [String], rate: Double, segment: String, attempts: Int, region: String, ceiling: Double, status: BatchedOvertimePlanStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.threshold = threshold
            self.tags = tags
            self.rate = rate
            self.segment = segment
            self.attempts = attempts
            self.region = region
            self.ceiling = ceiling
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

        func canMoveTo(_ next: BatchedOvertimePlanStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == BatchedOvertimePlanStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: BatchedOvertimePlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched overtime plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedVolume() -> Double {
            return ((ceiling + rate) * 100).rounded() / 100
        }

        func copyValue() -> BatchedOvertimePlan {
            return BatchedOvertimePlan(
                code: code,
                name: name,
                patientRef: patientRef,
                threshold: threshold,
                tags: tags,
                rate: rate,
                segment: segment,
                attempts: attempts,
                region: region,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a batched overtime plan in status draft.
    static func newBatchedOvertimePlan(_ code: String, name: String) -> BatchedOvertimePlan {
        return BatchedOvertimePlan(
            code: code,
            name: name,
            patientRef: "",
            threshold: 0.0,
            tags: [],
            rate: 0.0,
            segment: "",
            attempts: 0,
            region: "",
            ceiling: 0.0,
            status: BatchedOvertimePlanStatus.draft
        )
    }
}
