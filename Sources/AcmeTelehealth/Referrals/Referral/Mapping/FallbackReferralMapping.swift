import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback referral mapping is in its life cycle.
    enum FallbackReferralMappingStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One fallback referral mapping, with what the planners need to act on it.
    final class FallbackReferralMapping {
        var code: String
        var label: String
        var clinicianID: String
        var budget: Double
        var margin: Double
        var procedureCode: String
        var status: FallbackReferralMappingStatus

        init(code: String, label: String, clinicianID: String, budget: Double, margin: Double, procedureCode: String, status: FallbackReferralMappingStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.budget = budget
            self.margin = margin
            self.procedureCode = procedureCode
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

        func canMoveTo(_ next: FallbackReferralMappingStatus) -> Bool {
            switch status {
            case .draft:
                return next == FallbackReferralMappingStatus.pending || next == FallbackReferralMappingStatus.suspended
            case .pending:
                return next == FallbackReferralMappingStatus.closed
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == FallbackReferralMappingStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackReferralMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback referral mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback referral mapping") \(code)"
        }

        func effectiveExposure() -> Double {
            return (margin * budget * 100).rounded() / 100
        }

        func copyValue() -> FallbackReferralMapping {
            return FallbackReferralMapping(
                code: code,
                label: label,
                clinicianID: clinicianID,
                budget: budget,
                margin: margin,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback referral mapping in status draft.
    static func newFallbackReferralMapping(_ code: String, label: String) -> FallbackReferralMapping {
        return FallbackReferralMapping(
            code: code,
            label: label,
            clinicianID: "",
            budget: 0.0,
            margin: 0.0,
            procedureCode: "",
            status: FallbackReferralMappingStatus.draft
        )
    }
}
