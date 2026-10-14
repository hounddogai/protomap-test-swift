import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim proposal is in its life cycle.
    enum ClaimProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One claim proposal, with what the planners need to act on it.
    final class ClaimProposal {
        var code: String
        var name: String
        var label: String
        var endsAt: Int
        var score: Double
        var revision: Int
        var description: String
        var weight: Double
        var ownerID: String
        var bed: String
        var active: Bool
        var status: ClaimProposalStatus

        init(code: String, name: String, label: String, endsAt: Int, score: Double, revision: Int, description: String, weight: Double, ownerID: String, bed: String, active: Bool, status: ClaimProposalStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.endsAt = endsAt
            self.score = score
            self.revision = revision
            self.description = description
            self.weight = weight
            self.ownerID = ownerID
            self.bed = bed
            self.active = active
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

        func canMoveTo(_ next: ClaimProposalStatus) -> Bool {
            switch status {
            case .planned:
                return next == ClaimProposalStatus.completed
            case .scheduled:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ClaimProposalStatus.cancelled
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

        func moveTo(_ next: ClaimProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\("claim proposal") \(code)"
        }

        func effectiveVolume() -> Double {
            return (Double(endsAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> ClaimProposal {
            return ClaimProposal(
                code: code,
                name: name,
                label: label,
                endsAt: endsAt,
                score: score,
                revision: revision,
                description: description,
                weight: weight,
                ownerID: ownerID,
                bed: bed,
                active: active,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a claim proposal in status planned.
    static func newClaimProposal(_ code: String, name: String) -> ClaimProposal {
        return ClaimProposal(
            code: code,
            name: name,
            label: "",
            endsAt: 0,
            score: 0.0,
            revision: 0,
            description: "",
            weight: 0.0,
            ownerID: "",
            bed: "",
            active: false,
            status: ClaimProposalStatus.planned
        )
    }
}
