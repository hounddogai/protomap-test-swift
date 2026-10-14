import AcmePlatform
import Foundation

extension Labs {
    /// Where a batched panel milestone is in its life cycle.
    enum BatchedPanelMilestoneStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A batched panel milestone. Its code is unique within a tenant.
    final class BatchedPanelMilestone {
        var code: String
        var name: String
        var endsAt: Int
        var facility: String
        var acuity: Int
        var encounterID: String
        var status: BatchedPanelMilestoneStatus

        init(code: String, name: String, endsAt: Int, facility: String, acuity: Int, encounterID: String, status: BatchedPanelMilestoneStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.facility = facility
            self.acuity = acuity
            self.encounterID = encounterID
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

        func canMoveTo(_ next: BatchedPanelMilestoneStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == BatchedPanelMilestoneStatus.running
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == BatchedPanelMilestoneStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedPanelMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched panel milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("batched panel milestone") \(code)"
        }

        func projectedLoad() -> Double {
            return (Double(acuity) * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> BatchedPanelMilestone {
            return BatchedPanelMilestone(
                code: code,
                name: name,
                endsAt: endsAt,
                facility: facility,
                acuity: acuity,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a batched panel milestone in status new.
    static func newBatchedPanelMilestone(_ code: String, name: String) -> BatchedPanelMilestone {
        return BatchedPanelMilestone(
            code: code,
            name: name,
            endsAt: 0,
            facility: "",
            acuity: 0,
            encounterID: "",
            status: BatchedPanelMilestoneStatus.new
        )
    }
}
