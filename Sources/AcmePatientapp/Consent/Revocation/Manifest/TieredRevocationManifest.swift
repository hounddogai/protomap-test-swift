import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered revocation manifest is in its life cycle.
    enum TieredRevocationManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A tiered revocation manifest as the revocation team keeps it.
    final class TieredRevocationManifest {
        var code: String
        var label: String
        var country: String
        var attempts: Int
        var minimum: Double
        var dosageMg: Double
        var status: TieredRevocationManifestStatus

        init(code: String, label: String, country: String, attempts: Int, minimum: Double, dosageMg: Double, status: TieredRevocationManifestStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.attempts = attempts
            self.minimum = minimum
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: TieredRevocationManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == TieredRevocationManifestStatus.reopened || next == TieredRevocationManifestStatus.archived
            case .inReview:
                switch next {
                case .resolved:
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
                return next == TieredRevocationManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredRevocationManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered revocation manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(attempts) - minimum) * 100).rounded() / 100
        }

        func copyValue() -> TieredRevocationManifest {
            return TieredRevocationManifest(
                code: code,
                label: label,
                country: country,
                attempts: attempts,
                minimum: minimum,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered revocation manifest in status open.
    static func newTieredRevocationManifest(_ code: String, label: String) -> TieredRevocationManifest {
        return TieredRevocationManifest(
            code: code,
            label: label,
            country: "",
            attempts: 0,
            minimum: 0.0,
            dosageMg: 0.0,
            status: TieredRevocationManifestStatus.`open`
        )
    }
}
