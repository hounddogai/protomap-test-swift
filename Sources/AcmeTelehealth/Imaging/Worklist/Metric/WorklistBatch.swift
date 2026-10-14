import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist batch is in its life cycle.
    enum WorklistBatchStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A worklist batch. Its code is unique within a tenant.
    final class WorklistBatch {
        var code: String
        var label: String
        var country: String
        var region: String
        var segment: String
        var threshold: Double
        var unit: String
        var summary: String
        var budget: Double
        var status: WorklistBatchStatus

        init(code: String, label: String, country: String, region: String, segment: String, threshold: Double, unit: String, summary: String, budget: Double, status: WorklistBatchStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.region = region
            self.segment = segment
            self.threshold = threshold
            self.unit = unit
            self.summary = summary
            self.budget = budget
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistBatchStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WorklistBatchStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WorklistBatchStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedVolume() -> Double {
            return ((threshold + budget) * 100).rounded() / 100
        }

        func copyValue() -> WorklistBatch {
            return WorklistBatch(
                code: code,
                label: label,
                country: country,
                region: region,
                segment: segment,
                threshold: threshold,
                unit: unit,
                summary: summary,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a worklist batch in status proposed.
    static func newWorklistBatch(_ code: String, label: String) -> WorklistBatch {
        return WorklistBatch(
            code: code,
            label: label,
            country: "",
            region: "",
            segment: "",
            threshold: 0.0,
            unit: "",
            summary: "",
            budget: 0.0,
            status: WorklistBatchStatus.proposed
        )
    }
}
