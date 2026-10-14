import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched care gap estimate is in its life cycle.
    enum BatchedCareGapEstimateStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a batched care gap estimate and its current status.
    final class BatchedCareGapEstimate {
        var code: String
        var label: String
        var visitMinutes: Int
        var name: String
        var patientRef: String
        var limit: Int
        var contactEmail: String
        var status: BatchedCareGapEstimateStatus

        init(code: String, label: String, visitMinutes: Int, name: String, patientRef: String, limit: Int, contactEmail: String, status: BatchedCareGapEstimateStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.name = name
            self.patientRef = patientRef
            self.limit = limit
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: BatchedCareGapEstimateStatus) -> Bool {
            switch status {
            case .planned:
                return next == BatchedCareGapEstimateStatus.completed
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == BatchedCareGapEstimateStatus.completed || next == BatchedCareGapEstimateStatus.cancelled
            case .completed:
                return next == BatchedCareGapEstimateStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedCareGapEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched care gap estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched care gap estimate") \(code)"
        }

        func netExposure() -> Double {
            return (Double(visitMinutes) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> BatchedCareGapEstimate {
            return BatchedCareGapEstimate(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                name: name,
                patientRef: patientRef,
                limit: limit,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched care gap estimate in status planned.
    static func newBatchedCareGapEstimate(_ code: String, label: String) -> BatchedCareGapEstimate {
        return BatchedCareGapEstimate(
            code: code,
            label: label,
            visitMinutes: 0,
            name: "",
            patientRef: "",
            limit: 0,
            contactEmail: "",
            status: BatchedCareGapEstimateStatus.planned
        )
    }
}
