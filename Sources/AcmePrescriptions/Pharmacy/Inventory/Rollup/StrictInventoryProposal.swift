import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict inventory proposal is in its life cycle.
    enum StrictInventoryProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict inventory proposal as the inventory team keeps it.
    final class StrictInventoryProposal {
        var code: String
        var label: String
        var ownerID: String
        var reviewer: String
        var channel: String
        var visible: Bool
        var rate: Double
        var margin: Double
        var limit: Int
        var attempts: Int
        var minimum: Double
        var status: StrictInventoryProposalStatus

        init(code: String, label: String, ownerID: String, reviewer: String, channel: String, visible: Bool, rate: Double, margin: Double, limit: Int, attempts: Int, minimum: Double, status: StrictInventoryProposalStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.reviewer = reviewer
            self.channel = channel
            self.visible = visible
            self.rate = rate
            self.margin = margin
            self.limit = limit
            self.attempts = attempts
            self.minimum = minimum
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

        func canMoveTo(_ next: StrictInventoryProposalStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictInventoryProposalStatus.published
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: StrictInventoryProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict inventory proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((rate + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> StrictInventoryProposal {
            return StrictInventoryProposal(
                code: code,
                label: label,
                ownerID: ownerID,
                reviewer: reviewer,
                channel: channel,
                visible: visible,
                rate: rate,
                margin: margin,
                limit: limit,
                attempts: attempts,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a strict inventory proposal in status created.
    static func newStrictInventoryProposal(_ code: String, label: String) -> StrictInventoryProposal {
        return StrictInventoryProposal(
            code: code,
            label: label,
            ownerID: "",
            reviewer: "",
            channel: "",
            visible: false,
            rate: 0.0,
            margin: 0.0,
            limit: 0,
            attempts: 0,
            minimum: 0.0,
            status: StrictInventoryProposalStatus.created
        )
    }
}
