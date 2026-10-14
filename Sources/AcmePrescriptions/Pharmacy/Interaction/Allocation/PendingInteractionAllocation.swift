import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a pending interaction allocation is in its life cycle.
    enum PendingInteractionAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One pending interaction allocation, with what the planners need to act on it.
    final class PendingInteractionAllocation {
        var code: String
        var label: String
        var endsAt: Int
        var expiresAt: Int
        var retries: Int
        var facility: String
        var patientRef: String
        var batchSize: Int
        var approved: Bool
        var margin: Double
        var status: PendingInteractionAllocationStatus

        init(code: String, label: String, endsAt: Int, expiresAt: Int, retries: Int, facility: String, patientRef: String, batchSize: Int, approved: Bool, margin: Double, status: PendingInteractionAllocationStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.expiresAt = expiresAt
            self.retries = retries
            self.facility = facility
            self.patientRef = patientRef
            self.batchSize = batchSize
            self.approved = approved
            self.margin = margin
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

        func canMoveTo(_ next: PendingInteractionAllocationStatus) -> Bool {
            switch status {
            case .planned:
                return next == PendingInteractionAllocationStatus.inProgress || next == PendingInteractionAllocationStatus.cancelled
            case .scheduled:
                return next == PendingInteractionAllocationStatus.cancelled
            case .inProgress:
                return next == PendingInteractionAllocationStatus.completed
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: PendingInteractionAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending interaction allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending interaction allocation") \(code)"
        }

        func projectedVolume() -> Double {
            return ((Double(retries) + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingInteractionAllocation {
            return PendingInteractionAllocation(
                code: code,
                label: label,
                endsAt: endsAt,
                expiresAt: expiresAt,
                retries: retries,
                facility: facility,
                patientRef: patientRef,
                batchSize: batchSize,
                approved: approved,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a pending interaction allocation in status planned.
    static func newPendingInteractionAllocation(_ code: String, label: String) -> PendingInteractionAllocation {
        return PendingInteractionAllocation(
            code: code,
            label: label,
            endsAt: 0,
            expiresAt: 0,
            retries: 0,
            facility: "",
            patientRef: "",
            batchSize: 0,
            approved: false,
            margin: 0.0,
            status: PendingInteractionAllocationStatus.planned
        )
    }
}
