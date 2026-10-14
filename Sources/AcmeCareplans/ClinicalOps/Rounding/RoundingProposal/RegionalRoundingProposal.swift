import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a regional rounding proposal is in its life cycle.
    enum RegionalRoundingProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a regional rounding proposal and its current status.
    final class RegionalRoundingProposal {
        var code: String
        var label: String
        var diagnosisCode: String
        var specialty: String
        var ratio: Double
        var contactEmail: String
        var dosageMg: Double
        var region: String
        var weight: Double
        var status: RegionalRoundingProposalStatus

        init(code: String, label: String, diagnosisCode: String, specialty: String, ratio: Double, contactEmail: String, dosageMg: Double, region: String, weight: Double, status: RegionalRoundingProposalStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.specialty = specialty
            self.ratio = ratio
            self.contactEmail = contactEmail
            self.dosageMg = dosageMg
            self.region = region
            self.weight = weight
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

        func canMoveTo(_ next: RegionalRoundingProposalStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == RegionalRoundingProposalStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RegionalRoundingProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional rounding proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("regional rounding proposal") \(code)"
        }

        func netLoad() -> Double {
            return ((ratio - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> RegionalRoundingProposal {
            return RegionalRoundingProposal(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                specialty: specialty,
                ratio: ratio,
                contactEmail: contactEmail,
                dosageMg: dosageMg,
                region: region,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional rounding proposal in status planned.
    static func newRegionalRoundingProposal(_ code: String, label: String) -> RegionalRoundingProposal {
        return RegionalRoundingProposal(
            code: code,
            label: label,
            diagnosisCode: "",
            specialty: "",
            ratio: 0.0,
            contactEmail: "",
            dosageMg: 0.0,
            region: "",
            weight: 0.0,
            status: RegionalRoundingProposalStatus.planned
        )
    }
}
