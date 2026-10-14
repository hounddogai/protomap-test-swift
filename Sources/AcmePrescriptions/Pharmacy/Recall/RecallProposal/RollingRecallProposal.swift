import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling recall proposal is in its life cycle.
    enum RollingRecallProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling recall proposal, with what the planners need to act on it.
    final class RollingRecallProposal {
        var code: String
        var label: String
        var pinned: Bool
        var ratio: Double
        var procedureCode: String
        var region: String
        var locale: String
        var endsAt: Int
        var encounterID: String
        var status: RollingRecallProposalStatus

        init(code: String, label: String, pinned: Bool, ratio: Double, procedureCode: String, region: String, locale: String, endsAt: Int, encounterID: String, status: RollingRecallProposalStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.region = region
            self.locale = locale
            self.endsAt = endsAt
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RollingRecallProposalStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == RollingRecallProposalStatus.resolved || next == RollingRecallProposalStatus.archived
            case .resolved:
                return next == RollingRecallProposalStatus.reopened || next == RollingRecallProposalStatus.archived
            case .reopened:
                return next == RollingRecallProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingRecallProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling recall proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netVolume() -> Double {
            return (ratio * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> RollingRecallProposal {
            return RollingRecallProposal(
                code: code,
                label: label,
                pinned: pinned,
                ratio: ratio,
                procedureCode: procedureCode,
                region: region,
                locale: locale,
                endsAt: endsAt,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling recall proposal in status open.
    static func newRollingRecallProposal(_ code: String, label: String) -> RollingRecallProposal {
        return RollingRecallProposal(
            code: code,
            label: label,
            pinned: false,
            ratio: 0.0,
            procedureCode: "",
            region: "",
            locale: "",
            endsAt: 0,
            encounterID: "",
            status: RollingRecallProposalStatus.`open`
        )
    }
}
