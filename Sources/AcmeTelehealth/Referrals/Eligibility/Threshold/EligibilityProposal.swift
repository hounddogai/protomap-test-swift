import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility proposal is in its life cycle.
    enum EligibilityProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A eligibility proposal. Its code is unique within a tenant.
    final class EligibilityProposal {
        var code: String
        var label: String
        var batchSize: Int
        var visitMinutes: Int
        var channel: String
        var diagnosisCode: String
        var reviewer: String
        var minimum: Double
        var windowDays: Int
        var status: EligibilityProposalStatus

        init(code: String, label: String, batchSize: Int, visitMinutes: Int, channel: String, diagnosisCode: String, reviewer: String, minimum: Double, windowDays: Int, status: EligibilityProposalStatus) {
            self.code = code
            self.label = label
            self.batchSize = batchSize
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.diagnosisCode = diagnosisCode
            self.reviewer = reviewer
            self.minimum = minimum
            self.windowDays = windowDays
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

        func canMoveTo(_ next: EligibilityProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == EligibilityProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: EligibilityProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netLoad() -> Double {
            return (Double(windowDays) * minimum * 100).rounded() / 100
        }

        func copyValue() -> EligibilityProposal {
            return EligibilityProposal(
                code: code,
                label: label,
                batchSize: batchSize,
                visitMinutes: visitMinutes,
                channel: channel,
                diagnosisCode: diagnosisCode,
                reviewer: reviewer,
                minimum: minimum,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a eligibility proposal in status created.
    static func newEligibilityProposal(_ code: String, label: String) -> EligibilityProposal {
        return EligibilityProposal(
            code: code,
            label: label,
            batchSize: 0,
            visitMinutes: 0,
            channel: "",
            diagnosisCode: "",
            reviewer: "",
            minimum: 0.0,
            windowDays: 0,
            status: EligibilityProposalStatus.created
        )
    }
}
