import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial proposal is in its life cycle.
    enum DenialProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A denial proposal. Its code is unique within a tenant.
    final class DenialProposal {
        var code: String
        var title: String
        var payer: String
        var endsAt: Int
        var bed: String
        var updatedAt: Int
        var acuity: Int
        var contactEmail: String
        var amount: Double
        var diagnosisCode: String
        var status: DenialProposalStatus

        init(code: String, title: String, payer: String, endsAt: Int, bed: String, updatedAt: Int, acuity: Int, contactEmail: String, amount: Double, diagnosisCode: String, status: DenialProposalStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.endsAt = endsAt
            self.bed = bed
            self.updatedAt = updatedAt
            self.acuity = acuity
            self.contactEmail = contactEmail
            self.amount = amount
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: DenialProposalStatus) -> Bool {
            switch status {
            case .planned:
                return next == DenialProposalStatus.inProgress
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DenialProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedValue() -> Double {
            return ((Double(acuity) + amount) * 100).rounded() / 100
        }

        func copyValue() -> DenialProposal {
            return DenialProposal(
                code: code,
                title: title,
                payer: payer,
                endsAt: endsAt,
                bed: bed,
                updatedAt: updatedAt,
                acuity: acuity,
                contactEmail: contactEmail,
                amount: amount,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial proposal in status planned.
    static func newDenialProposal(_ code: String, title: String) -> DenialProposal {
        return DenialProposal(
            code: code,
            title: title,
            payer: "",
            endsAt: 0,
            bed: "",
            updatedAt: 0,
            acuity: 0,
            contactEmail: "",
            amount: 0.0,
            diagnosisCode: "",
            status: DenialProposalStatus.planned
        )
    }
}
