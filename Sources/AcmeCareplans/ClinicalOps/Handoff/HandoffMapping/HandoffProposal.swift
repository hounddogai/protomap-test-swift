import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a handoff proposal is in its life cycle.
    enum HandoffProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A handoff proposal as the handoff team keeps it.
    final class HandoffProposal {
        var code: String
        var name: String
        var phone: String
        var attributes: [String: String]
        var maximum: Double
        var version: Int
        var amount: Double
        var specialty: String
        var status: HandoffProposalStatus

        init(code: String, name: String, phone: String, attributes: [String: String], maximum: Double, version: Int, amount: Double, specialty: String, status: HandoffProposalStatus) {
            self.code = code
            self.name = name
            self.phone = phone
            self.attributes = attributes
            self.maximum = maximum
            self.version = version
            self.amount = amount
            self.specialty = specialty
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

        func canMoveTo(_ next: HandoffProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == HandoffProposalStatus.inReview
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == HandoffProposalStatus.reopened
            case .reopened:
                return next == HandoffProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: HandoffProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("handoff proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("handoff proposal") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveValue() -> Double {
            return ((maximum - amount) * 100).rounded() / 100
        }

        func copyValue() -> HandoffProposal {
            return HandoffProposal(
                code: code,
                name: name,
                phone: phone,
                attributes: attributes,
                maximum: maximum,
                version: version,
                amount: amount,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a handoff proposal in status open.
    static func newHandoffProposal(_ code: String, name: String) -> HandoffProposal {
        return HandoffProposal(
            code: code,
            name: name,
            phone: "",
            attributes: [:],
            maximum: 0.0,
            version: 0,
            amount: 0.0,
            specialty: "",
            status: HandoffProposalStatus.`open`
        )
    }
}
