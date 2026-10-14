import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap proposal is in its life cycle.
    enum CareGapProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A care gap proposal. Its code is unique within a tenant.
    final class CareGapProposal {
        var code: String
        var label: String
        var allergy: String
        var endsAt: Int
        var patientRef: String
        var attempts: Int
        var status: CareGapProposalStatus

        init(code: String, label: String, allergy: String, endsAt: Int, patientRef: String, attempts: Int, status: CareGapProposalStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.endsAt = endsAt
            self.patientRef = patientRef
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapProposalStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == CareGapProposalStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: CareGapProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("care gap proposal") \(code)"
        }

        func weightedLoad() -> Double {
            return ((Double(endsAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> CareGapProposal {
            return CareGapProposal(
                code: code,
                label: label,
                allergy: allergy,
                endsAt: endsAt,
                patientRef: patientRef,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care gap proposal in status draft.
    static func newCareGapProposal(_ code: String, label: String) -> CareGapProposal {
        return CareGapProposal(
            code: code,
            label: label,
            allergy: "",
            endsAt: 0,
            patientRef: "",
            attempts: 0,
            status: CareGapProposalStatus.draft
        )
    }
}
