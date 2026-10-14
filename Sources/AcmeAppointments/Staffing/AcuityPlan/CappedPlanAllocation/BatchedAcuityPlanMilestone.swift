import AcmePlatform
import Foundation

extension Staffing {
    /// Where a batched acuity plan milestone is in its life cycle.
    enum BatchedAcuityPlanMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A batched acuity plan milestone as the acuity plan team keeps it.
    final class BatchedAcuityPlanMilestone {
        var code: String
        var label: String
        var bed: String
        var region: String
        var copay: Double
        var visitMinutes: Int
        var notes: String
        var maximum: Double
        var category: String
        var clinicianID: String
        var priority: Int
        var status: BatchedAcuityPlanMilestoneStatus

        init(code: String, label: String, bed: String, region: String, copay: Double, visitMinutes: Int, notes: String, maximum: Double, category: String, clinicianID: String, priority: Int, status: BatchedAcuityPlanMilestoneStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.region = region
            self.copay = copay
            self.visitMinutes = visitMinutes
            self.notes = notes
            self.maximum = maximum
            self.category = category
            self.clinicianID = clinicianID
            self.priority = priority
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

        func canMoveTo(_ next: BatchedAcuityPlanMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                return next == BatchedAcuityPlanMilestoneStatus.reopened || next == BatchedAcuityPlanMilestoneStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == BatchedAcuityPlanMilestoneStatus.reopened || next == BatchedAcuityPlanMilestoneStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: BatchedAcuityPlanMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched acuity plan milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netExposure() -> Double {
            return ((maximum + copay) * 100).rounded() / 100
        }

        func copyValue() -> BatchedAcuityPlanMilestone {
            return BatchedAcuityPlanMilestone(
                code: code,
                label: label,
                bed: bed,
                region: region,
                copay: copay,
                visitMinutes: visitMinutes,
                notes: notes,
                maximum: maximum,
                category: category,
                clinicianID: clinicianID,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a batched acuity plan milestone in status open.
    static func newBatchedAcuityPlanMilestone(_ code: String, label: String) -> BatchedAcuityPlanMilestone {
        return BatchedAcuityPlanMilestone(
            code: code,
            label: label,
            bed: "",
            region: "",
            copay: 0.0,
            visitMinutes: 0,
            notes: "",
            maximum: 0.0,
            category: "",
            clinicianID: "",
            priority: 0,
            status: BatchedAcuityPlanMilestoneStatus.`open`
        )
    }
}
