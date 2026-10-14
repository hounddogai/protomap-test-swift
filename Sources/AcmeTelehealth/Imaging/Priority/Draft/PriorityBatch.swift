import AcmePlatform
import Foundation

extension Imaging {
    /// Where a priority batch is in its life cycle.
    enum PriorityBatchStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A priority batch as the priority team keeps it.
    final class PriorityBatch {
        var code: String
        var label: String
        var margin: Double
        var ceiling: Double
        var region: String
        var graceDays: Int
        var notes: String
        var copay: Double
        var allergy: String
        var score: Double
        var status: PriorityBatchStatus

        init(code: String, label: String, margin: Double, ceiling: Double, region: String, graceDays: Int, notes: String, copay: Double, allergy: String, score: Double, status: PriorityBatchStatus) {
            self.code = code
            self.label = label
            self.margin = margin
            self.ceiling = ceiling
            self.region = region
            self.graceDays = graceDays
            self.notes = notes
            self.copay = copay
            self.allergy = allergy
            self.score = score
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

        func canMoveTo(_ next: PriorityBatchStatus) -> Bool {
            switch status {
            case .created:
                return next == PriorityBatchStatus.validated || next == PriorityBatchStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == PriorityBatchStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PriorityBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("priority batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netExposure() -> Double {
            return (copay * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> PriorityBatch {
            return PriorityBatch(
                code: code,
                label: label,
                margin: margin,
                ceiling: ceiling,
                region: region,
                graceDays: graceDays,
                notes: notes,
                copay: copay,
                allergy: allergy,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a priority batch in status created.
    static func newPriorityBatch(_ code: String, label: String) -> PriorityBatch {
        return PriorityBatch(
            code: code,
            label: label,
            margin: 0.0,
            ceiling: 0.0,
            region: "",
            graceDays: 0,
            notes: "",
            copay: 0.0,
            allergy: "",
            score: 0.0,
            status: PriorityBatchStatus.created
        )
    }
}
