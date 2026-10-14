import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched accession plan is in its life cycle.
    enum BatchedAccessionPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One batched accession plan, with what the planners need to act on it.
    final class BatchedAccessionPlan {
        var code: String
        var title: String
        var ownerID: String
        var description: String
        var timezone: String
        var name: String
        var channel: String
        var procedureCode: String
        var threshold: Double
        var status: BatchedAccessionPlanStatus

        init(code: String, title: String, ownerID: String, description: String, timezone: String, name: String, channel: String, procedureCode: String, threshold: Double, status: BatchedAccessionPlanStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.description = description
            self.timezone = timezone
            self.name = name
            self.channel = channel
            self.procedureCode = procedureCode
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedAccessionPlanStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedAccessionPlanStatus.done || next == BatchedAccessionPlanStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedAccessionPlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAccessionPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched accession plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return threshold
        }

        func copyValue() -> BatchedAccessionPlan {
            return BatchedAccessionPlan(
                code: code,
                title: title,
                ownerID: ownerID,
                description: description,
                timezone: timezone,
                name: name,
                channel: channel,
                procedureCode: procedureCode,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched accession plan in status new.
    static func newBatchedAccessionPlan(_ code: String, title: String) -> BatchedAccessionPlan {
        return BatchedAccessionPlan(
            code: code,
            title: title,
            ownerID: "",
            description: "",
            timezone: "",
            name: "",
            channel: "",
            procedureCode: "",
            threshold: 0.0,
            status: BatchedAccessionPlanStatus.new
        )
    }
}
