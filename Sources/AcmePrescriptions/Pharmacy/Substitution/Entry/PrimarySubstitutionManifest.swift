import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary substitution manifest is in its life cycle.
    enum PrimarySubstitutionManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary substitution manifest as the substitution team keeps it.
    final class PrimarySubstitutionManifest {
        var code: String
        var label: String
        var allergy: String
        var contactEmail: String
        var threshold: Double
        var discount: Double
        var status: PrimarySubstitutionManifestStatus

        init(code: String, label: String, allergy: String, contactEmail: String, threshold: Double, discount: Double, status: PrimarySubstitutionManifestStatus) {
            self.code = code
            self.label = label
            self.allergy = allergy
            self.contactEmail = contactEmail
            self.threshold = threshold
            self.discount = discount
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

        func canMoveTo(_ next: PrimarySubstitutionManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended, .closed:
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
                switch next {
                case .closed:
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

        func moveTo(_ next: PrimarySubstitutionManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary substitution manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func effectiveLoad() -> Double {
            return ((discount - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PrimarySubstitutionManifest {
            return PrimarySubstitutionManifest(
                code: code,
                label: label,
                allergy: allergy,
                contactEmail: contactEmail,
                threshold: threshold,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary substitution manifest in status draft.
    static func newPrimarySubstitutionManifest(_ code: String, label: String) -> PrimarySubstitutionManifest {
        return PrimarySubstitutionManifest(
            code: code,
            label: label,
            allergy: "",
            contactEmail: "",
            threshold: 0.0,
            discount: 0.0,
            status: PrimarySubstitutionManifestStatus.draft
        )
    }
}
