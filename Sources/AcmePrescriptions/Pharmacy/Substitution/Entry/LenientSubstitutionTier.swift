import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient substitution tier is in its life cycle.
    enum LenientSubstitutionTierStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One lenient substitution tier, with what the planners need to act on it.
    final class LenientSubstitutionTier {
        var code: String
        var title: String
        var copay: Double
        var clinicianID: String
        var discount: Double
        var ownerID: String
        var threshold: Double
        var status: LenientSubstitutionTierStatus

        init(code: String, title: String, copay: Double, clinicianID: String, discount: Double, ownerID: String, threshold: Double, status: LenientSubstitutionTierStatus) {
            self.code = code
            self.title = title
            self.copay = copay
            self.clinicianID = clinicianID
            self.discount = discount
            self.ownerID = ownerID
            self.threshold = threshold
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

        func canMoveTo(_ next: LenientSubstitutionTierStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: LenientSubstitutionTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient substitution tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient substitution tier") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((threshold - discount) * 100).rounded() / 100
        }

        func copyValue() -> LenientSubstitutionTier {
            return LenientSubstitutionTier(
                code: code,
                title: title,
                copay: copay,
                clinicianID: clinicianID,
                discount: discount,
                ownerID: ownerID,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient substitution tier in status draft.
    static func newLenientSubstitutionTier(_ code: String, title: String) -> LenientSubstitutionTier {
        return LenientSubstitutionTier(
            code: code,
            title: title,
            copay: 0.0,
            clinicianID: "",
            discount: 0.0,
            ownerID: "",
            threshold: 0.0,
            status: LenientSubstitutionTierStatus.draft
        )
    }
}
