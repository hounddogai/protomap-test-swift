import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a batched assessment estimate is in its life cycle.
    enum BatchedAssessmentEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched assessment estimate as the assessment team keeps it.
    final class BatchedAssessmentEstimate {
        var code: String
        var label: String
        var sequence: Int
        var active: Bool
        var amount: Double
        var procedureCode: String
        var externalRef: String
        var tags: [String]
        var category: String
        var minimum: Double
        var status: BatchedAssessmentEstimateStatus

        init(code: String, label: String, sequence: Int, active: Bool, amount: Double, procedureCode: String, externalRef: String, tags: [String], category: String, minimum: Double, status: BatchedAssessmentEstimateStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.active = active
            self.amount = amount
            self.procedureCode = procedureCode
            self.externalRef = externalRef
            self.tags = tags
            self.category = category
            self.minimum = minimum
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

        func canMoveTo(_ next: BatchedAssessmentEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedAssessmentEstimateStatus.pending || next == BatchedAssessmentEstimateStatus.suspended
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == BatchedAssessmentEstimateStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedAssessmentEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched assessment estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched assessment estimate") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedLoad() -> Double {
            return (Double(sequence) * minimum * 100).rounded() / 100
        }

        func copyValue() -> BatchedAssessmentEstimate {
            return BatchedAssessmentEstimate(
                code: code,
                label: label,
                sequence: sequence,
                active: active,
                amount: amount,
                procedureCode: procedureCode,
                externalRef: externalRef,
                tags: tags,
                category: category,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a batched assessment estimate in status draft.
    static func newBatchedAssessmentEstimate(_ code: String, label: String) -> BatchedAssessmentEstimate {
        return BatchedAssessmentEstimate(
            code: code,
            label: label,
            sequence: 0,
            active: false,
            amount: 0.0,
            procedureCode: "",
            externalRef: "",
            tags: [],
            category: "",
            minimum: 0.0,
            status: BatchedAssessmentEstimateStatus.draft
        )
    }
}
