import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy order set proposal is in its life cycle.
    enum LegacyOrderSetProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy order set proposal as the order set team keeps it.
    final class LegacyOrderSetProposal {
        var code: String
        var label: String
        var payer: String
        var rate: Double
        var cost: Double
        var facility: String
        var dosageMg: Double
        var timezone: String
        var status: LegacyOrderSetProposalStatus

        init(code: String, label: String, payer: String, rate: Double, cost: Double, facility: String, dosageMg: Double, timezone: String, status: LegacyOrderSetProposalStatus) {
            self.code = code
            self.label = label
            self.payer = payer
            self.rate = rate
            self.cost = cost
            self.facility = facility
            self.dosageMg = dosageMg
            self.timezone = timezone
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

        func canMoveTo(_ next: LegacyOrderSetProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == LegacyOrderSetProposalStatus.draining
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == LegacyOrderSetProposalStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyOrderSetProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy order set proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveLoad() -> Double {
            return ((rate + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LegacyOrderSetProposal {
            return LegacyOrderSetProposal(
                code: code,
                label: label,
                payer: payer,
                rate: rate,
                cost: cost,
                facility: facility,
                dosageMg: dosageMg,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a legacy order set proposal in status idle.
    static func newLegacyOrderSetProposal(_ code: String, label: String) -> LegacyOrderSetProposal {
        return LegacyOrderSetProposal(
            code: code,
            label: label,
            payer: "",
            rate: 0.0,
            cost: 0.0,
            facility: "",
            dosageMg: 0.0,
            timezone: "",
            status: LegacyOrderSetProposalStatus.idle
        )
    }
}
