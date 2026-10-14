import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness proposal is in its life cycle.
    enum WitnessProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a witness proposal and its current status.
    final class WitnessProposal {
        var code: String
        var title: String
        var priority: Int
        var clinicianID: String
        var score: Double
        var name: String
        var contactEmail: String
        var status: WitnessProposalStatus

        init(code: String, title: String, priority: Int, clinicianID: String, score: Double, name: String, contactEmail: String, status: WitnessProposalStatus) {
            self.code = code
            self.title = title
            self.priority = priority
            self.clinicianID = clinicianID
            self.score = score
            self.name = name
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: WitnessProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == WitnessProposalStatus.draining
            case .warming:
                return next == WitnessProposalStatus.draining || next == WitnessProposalStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: WitnessProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("witness proposal") \(code)"
        }

        func netVolume() -> Double {
            return (score * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> WitnessProposal {
            return WitnessProposal(
                code: code,
                title: title,
                priority: priority,
                clinicianID: clinicianID,
                score: score,
                name: name,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a witness proposal in status idle.
    static func newWitnessProposal(_ code: String, title: String) -> WitnessProposal {
        return WitnessProposal(
            code: code,
            title: title,
            priority: 0,
            clinicianID: "",
            score: 0.0,
            name: "",
            contactEmail: "",
            status: WitnessProposalStatus.idle
        )
    }
}
