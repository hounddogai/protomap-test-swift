import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling care protocol agreement is in its life cycle.
    enum RollingCareProtocolAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a rolling care protocol agreement and its current status.
    final class RollingCareProtocolAgreement {
        var code: String
        var label: String
        var allergy: String
        var checksum: String
        var minimum: Double
        var budget: Double
        var region: String
        var procedureCode: String
        var status: RollingCareProtocolAgreementStatus

        init(code: String, label: String, allergy: String, checksum: String, minimum: Double, budget: Double, region: String, procedureCode: String, status: RollingCareProtocolAgreementStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.checksum = checksum
            self.minimum = minimum
            self.budget = budget
            self.region = region
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: RollingCareProtocolAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingCareProtocolAgreementStatus.reopened || next == RollingCareProtocolAgreementStatus.archived
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: RollingCareProtocolAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling care protocol agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling care protocol agreement") \(code)"
        }

        func effectiveValue() -> Double {
            return (minimum * budget * 100).rounded() / 100
        }

        func copyValue() -> RollingCareProtocolAgreement {
            return RollingCareProtocolAgreement(
                code: code,
                label: label,
                allergy: allergy,
                checksum: checksum,
                minimum: minimum,
                budget: budget,
                region: region,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling care protocol agreement in status open.
    static func newRollingCareProtocolAgreement(_ code: String, label: String) -> RollingCareProtocolAgreement {
        return RollingCareProtocolAgreement(
            code: code,
            label: label,
            allergy: "",
            checksum: "",
            minimum: 0.0,
            budget: 0.0,
            region: "",
            procedureCode: "",
            status: RollingCareProtocolAgreementStatus.`open`
        )
    }
}
