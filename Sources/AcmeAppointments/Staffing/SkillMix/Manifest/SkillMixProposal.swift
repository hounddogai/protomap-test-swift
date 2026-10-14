import AcmePlatform
import Foundation

extension Staffing {
    /// Where a skill mix proposal is in its life cycle.
    enum SkillMixProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A skill mix proposal. Its code is unique within a tenant.
    final class SkillMixProposal {
        var code: String
        var label: String
        var procedureCode: String
        var pinned: Bool
        var attempts: Int
        var diagnosisCode: String
        var discount: Double
        var createdAt: Int
        var status: SkillMixProposalStatus

        init(code: String, label: String, procedureCode: String, pinned: Bool, attempts: Int, diagnosisCode: String, discount: Double, createdAt: Int, status: SkillMixProposalStatus) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.pinned = pinned
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.discount = discount
            self.createdAt = createdAt
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

        func canMoveTo(_ next: SkillMixProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == SkillMixProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SkillMixProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("skill mix proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedTotal() -> Double {
            return ((Double(createdAt) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> SkillMixProposal {
            return SkillMixProposal(
                code: code,
                label: label,
                procedureCode: procedureCode,
                pinned: pinned,
                attempts: attempts,
                diagnosisCode: diagnosisCode,
                discount: discount,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a skill mix proposal in status created.
    static func newSkillMixProposal(_ code: String, label: String) -> SkillMixProposal {
        return SkillMixProposal(
            code: code,
            label: label,
            procedureCode: "",
            pinned: false,
            attempts: 0,
            diagnosisCode: "",
            discount: 0.0,
            createdAt: 0,
            status: SkillMixProposalStatus.created
        )
    }
}
