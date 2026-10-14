import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched program plan is in its life cycle.
    enum BatchedProgramPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a batched program plan and its current status.
    final class BatchedProgramPlan {
        var code: String
        var name: String
        var channel: String
        var weight: Double
        var graceDays: Int
        var retries: Int
        var refills: Int
        var visitMinutes: Int
        var sequence: Int
        var payer: String
        var archived: Bool
        var status: BatchedProgramPlanStatus

        init(code: String, name: String, channel: String, weight: Double, graceDays: Int, retries: Int, refills: Int, visitMinutes: Int, sequence: Int, payer: String, archived: Bool, status: BatchedProgramPlanStatus) {
            self.code = code
            self.name = name
            self.channel = channel
            self.weight = weight
            self.graceDays = graceDays
            self.retries = retries
            self.refills = refills
            self.visitMinutes = visitMinutes
            self.sequence = sequence
            self.payer = payer
            self.archived = archived
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedProgramPlanStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedProgramPlanStatus.archived
            case .inReview:
                return next == BatchedProgramPlanStatus.resolved
            case .resolved:
                return next == BatchedProgramPlanStatus.reopened
            case .reopened:
                return next == BatchedProgramPlanStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedProgramPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched program plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netVolume() -> Double {
            return ((Double(refills) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedProgramPlan {
            return BatchedProgramPlan(
                code: code,
                name: name,
                channel: channel,
                weight: weight,
                graceDays: graceDays,
                retries: retries,
                refills: refills,
                visitMinutes: visitMinutes,
                sequence: sequence,
                payer: payer,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched program plan in status open.
    static func newBatchedProgramPlan(_ code: String, name: String) -> BatchedProgramPlan {
        return BatchedProgramPlan(
            code: code,
            name: name,
            channel: "",
            weight: 0.0,
            graceDays: 0,
            retries: 0,
            refills: 0,
            visitMinutes: 0,
            sequence: 0,
            payer: "",
            archived: false,
            status: BatchedProgramPlanStatus.`open`
        )
    }
}
