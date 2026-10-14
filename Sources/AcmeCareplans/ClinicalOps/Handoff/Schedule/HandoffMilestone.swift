import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff milestone is in its life cycle.
    enum HandoffMilestoneStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A handoff milestone. Its code is unique within a tenant.
    final class HandoffMilestone {
        var code: String
        var label: String
        var durationMinutes: Int
        var category: String
        var updatedAt: Int
        var pinned: Bool
        var diagnosisCode: String
        var channel: String
        var rate: Double
        var status: HandoffMilestoneStatus

        init(code: String, label: String, durationMinutes: Int, category: String, updatedAt: Int, pinned: Bool, diagnosisCode: String, channel: String, rate: Double, status: HandoffMilestoneStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.category = category
            self.updatedAt = updatedAt
            self.pinned = pinned
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: HandoffMilestoneStatus) -> Bool {
            switch status {
            case .idle:
                return next == HandoffMilestoneStatus.stopped
            case .warming:
                return next == HandoffMilestoneStatus.ready
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == HandoffMilestoneStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedLoad() -> Double {
            return ((Double(durationMinutes) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> HandoffMilestone {
            return HandoffMilestone(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                category: category,
                updatedAt: updatedAt,
                pinned: pinned,
                diagnosisCode: diagnosisCode,
                channel: channel,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a handoff milestone in status idle.
    static func newHandoffMilestone(_ code: String, label: String) -> HandoffMilestone {
        return HandoffMilestone(
            code: code,
            label: label,
            durationMinutes: 0,
            category: "",
            updatedAt: 0,
            pinned: false,
            diagnosisCode: "",
            channel: "",
            rate: 0.0,
            status: HandoffMilestoneStatus.idle
        )
    }
}
