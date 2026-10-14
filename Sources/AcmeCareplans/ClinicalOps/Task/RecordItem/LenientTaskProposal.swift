import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a lenient task proposal is in its life cycle.
    enum LenientTaskProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A lenient task proposal as the task team keeps it.
    final class LenientTaskProposal {
        var code: String
        var label: String
        var notes: String
        var allergy: String
        var expiresAt: Int
        var version: Int
        var cost: Double
        var status: LenientTaskProposalStatus

        init(code: String, label: String, notes: String, allergy: String, expiresAt: Int, version: Int, cost: Double, status: LenientTaskProposalStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.version = version
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientTaskProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == LenientTaskProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientTaskProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient task proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("lenient task proposal") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(version) - cost) * 100).rounded() / 100
        }

        func copyValue() -> LenientTaskProposal {
            return LenientTaskProposal(
                code: code,
                label: label,
                notes: notes,
                allergy: allergy,
                expiresAt: expiresAt,
                version: version,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient task proposal in status proposed.
    static func newLenientTaskProposal(_ code: String, label: String) -> LenientTaskProposal {
        return LenientTaskProposal(
            code: code,
            label: label,
            notes: "",
            allergy: "",
            expiresAt: 0,
            version: 0,
            cost: 0.0,
            status: LenientTaskProposalStatus.proposed
        )
    }
}
