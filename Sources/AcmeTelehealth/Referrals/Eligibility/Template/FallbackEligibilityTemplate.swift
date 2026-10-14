import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback eligibility template is in its life cycle.
    enum FallbackEligibilityTemplateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A fallback eligibility template as the eligibility team keeps it.
    final class FallbackEligibilityTemplate {
        var code: String
        var label: String
        var archived: Bool
        var clinicianID: String
        var margin: Double
        var notes: String
        var rate: Double
        var dosageMg: Double
        var description: String
        var status: FallbackEligibilityTemplateStatus

        init(code: String, label: String, archived: Bool, clinicianID: String, margin: Double, notes: String, rate: Double, dosageMg: Double, description: String, status: FallbackEligibilityTemplateStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.clinicianID = clinicianID
            self.margin = margin
            self.notes = notes
            self.rate = rate
            self.dosageMg = dosageMg
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackEligibilityTemplateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FallbackEligibilityTemplateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackEligibilityTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback eligibility template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("fallback eligibility template") \(code)"
        }

        func effectiveVolume() -> Double {
            return (rate * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> FallbackEligibilityTemplate {
            return FallbackEligibilityTemplate(
                code: code,
                label: label,
                archived: archived,
                clinicianID: clinicianID,
                margin: margin,
                notes: notes,
                rate: rate,
                dosageMg: dosageMg,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a fallback eligibility template in status requested.
    static func newFallbackEligibilityTemplate(_ code: String, label: String) -> FallbackEligibilityTemplate {
        return FallbackEligibilityTemplate(
            code: code,
            label: label,
            archived: false,
            clinicianID: "",
            margin: 0.0,
            notes: "",
            rate: 0.0,
            dosageMg: 0.0,
            description: "",
            status: FallbackEligibilityTemplateStatus.requested
        )
    }
}
