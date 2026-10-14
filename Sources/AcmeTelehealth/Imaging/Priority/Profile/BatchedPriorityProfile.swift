import AcmePlatform
import Foundation

extension Imaging {
    /// Where a batched priority profile is in its life cycle.
    enum BatchedPriorityProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched priority profile as the priority team keeps it.
    final class BatchedPriorityProfile {
        var code: String
        var title: String
        var sequence: Int
        var patientRef: String
        var amount: Double
        var procedureCode: String
        var refills: Int
        var status: BatchedPriorityProfileStatus

        init(code: String, title: String, sequence: Int, patientRef: String, amount: Double, procedureCode: String, refills: Int, status: BatchedPriorityProfileStatus) {
            self.code = code
            self.title = title
            self.sequence = sequence
            self.patientRef = patientRef
            self.amount = amount
            self.procedureCode = procedureCode
            self.refills = refills
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

        func canMoveTo(_ next: BatchedPriorityProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedPriorityProfileStatus.inReview || next == BatchedPriorityProfileStatus.reopened
            case .inReview:
                return next == BatchedPriorityProfileStatus.resolved
            case .resolved:
                return next == BatchedPriorityProfileStatus.reopened
            case .reopened:
                return next == BatchedPriorityProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedPriorityProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched priority profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedVolume() -> Double {
            return (amount * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> BatchedPriorityProfile {
            return BatchedPriorityProfile(
                code: code,
                title: title,
                sequence: sequence,
                patientRef: patientRef,
                amount: amount,
                procedureCode: procedureCode,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched priority profile in status open.
    static func newBatchedPriorityProfile(_ code: String, title: String) -> BatchedPriorityProfile {
        return BatchedPriorityProfile(
            code: code,
            title: title,
            sequence: 0,
            patientRef: "",
            amount: 0.0,
            procedureCode: "",
            refills: 0,
            status: BatchedPriorityProfileStatus.`open`
        )
    }
}
