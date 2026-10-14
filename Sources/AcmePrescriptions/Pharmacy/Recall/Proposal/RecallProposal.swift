import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall proposal is in its life cycle.
    enum RecallProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A recall proposal as the recall team keeps it.
    final class RecallProposal {
        var code: String
        var label: String
        var acuity: Int
        var channel: String
        var timezone: String
        var country: String
        var margin: Double
        var status: RecallProposalStatus

        init(code: String, label: String, acuity: Int, channel: String, timezone: String, country: String, margin: Double, status: RecallProposalStatus) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.channel = channel
            self.timezone = timezone
            self.country = country
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

        func canMoveTo(_ next: RecallProposalStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RecallProposalStatus.completed || next == RecallProposalStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == RecallProposalStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((margin - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> RecallProposal {
            return RecallProposal(
                code: code,
                label: label,
                acuity: acuity,
                channel: channel,
                timezone: timezone,
                country: country,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a recall proposal in status planned.
    static func newRecallProposal(_ code: String, label: String) -> RecallProposal {
        return RecallProposal(
            code: code,
            label: label,
            acuity: 0,
            channel: "",
            timezone: "",
            country: "",
            margin: 0.0,
            status: RecallProposalStatus.planned
        )
    }
}
