import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a strict claim allocation is in its life cycle.
    enum StrictClaimAllocationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a strict claim allocation and its current status.
    final class StrictClaimAllocation {
        var code: String
        var label: String
        var region: String
        var startsAt: Int
        var updatedAt: Int
        var patientRef: String
        var visible: Bool
        var durationMinutes: Int
        var channel: String
        var revision: Int
        var endsAt: Int
        var status: StrictClaimAllocationStatus

        init(code: String, label: String, region: String, startsAt: Int, updatedAt: Int, patientRef: String, visible: Bool, durationMinutes: Int, channel: String, revision: Int, endsAt: Int, status: StrictClaimAllocationStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.startsAt = startsAt
            self.updatedAt = updatedAt
            self.patientRef = patientRef
            self.visible = visible
            self.durationMinutes = durationMinutes
            self.channel = channel
            self.revision = revision
            self.endsAt = endsAt
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

        func canMoveTo(_ next: StrictClaimAllocationStatus) -> Bool {
            switch status {
            case .planned:
                return next == StrictClaimAllocationStatus.scheduled || next == StrictClaimAllocationStatus.completed
            case .scheduled:
                return next == StrictClaimAllocationStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictClaimAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict claim allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return ((Double(endsAt) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictClaimAllocation {
            return StrictClaimAllocation(
                code: code,
                label: label,
                region: region,
                startsAt: startsAt,
                updatedAt: updatedAt,
                patientRef: patientRef,
                visible: visible,
                durationMinutes: durationMinutes,
                channel: channel,
                revision: revision,
                endsAt: endsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a strict claim allocation in status planned.
    static func newStrictClaimAllocation(_ code: String, label: String) -> StrictClaimAllocation {
        return StrictClaimAllocation(
            code: code,
            label: label,
            region: "",
            startsAt: 0,
            updatedAt: 0,
            patientRef: "",
            visible: false,
            durationMinutes: 0,
            channel: "",
            revision: 0,
            endsAt: 0,
            status: StrictClaimAllocationStatus.planned
        )
    }
}
