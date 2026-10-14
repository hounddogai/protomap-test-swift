import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual eligibility proposal is in its life cycle.
    enum ManualEligibilityProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A manual eligibility proposal. Its code is unique within a tenant.
    final class ManualEligibilityProposal {
        var code: String
        var title: String
        var attempts: Int
        var facility: String
        var label: String
        var diagnosisCode: String
        var patientRef: String
        var allergy: String
        var timezone: String
        var source: String
        var checksum: String
        var status: ManualEligibilityProposalStatus

        init(code: String, title: String, attempts: Int, facility: String, label: String, diagnosisCode: String, patientRef: String, allergy: String, timezone: String, source: String, checksum: String, status: ManualEligibilityProposalStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.facility = facility
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.patientRef = patientRef
            self.allergy = allergy
            self.timezone = timezone
            self.source = source
            self.checksum = checksum
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

        func canMoveTo(_ next: ManualEligibilityProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ManualEligibilityProposalStatus.inReview || next == ManualEligibilityProposalStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == ManualEligibilityProposalStatus.reopened || next == ManualEligibilityProposalStatus.archived
            case .reopened:
                return next == ManualEligibilityProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualEligibilityProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual eligibility proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(attempts)
        }

        func copyValue() -> ManualEligibilityProposal {
            return ManualEligibilityProposal(
                code: code,
                title: title,
                attempts: attempts,
                facility: facility,
                label: label,
                diagnosisCode: diagnosisCode,
                patientRef: patientRef,
                allergy: allergy,
                timezone: timezone,
                source: source,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a manual eligibility proposal in status open.
    static func newManualEligibilityProposal(_ code: String, title: String) -> ManualEligibilityProposal {
        return ManualEligibilityProposal(
            code: code,
            title: title,
            attempts: 0,
            facility: "",
            label: "",
            diagnosisCode: "",
            patientRef: "",
            allergy: "",
            timezone: "",
            source: "",
            checksum: "",
            status: ManualEligibilityProposalStatus.`open`
        )
    }
}
