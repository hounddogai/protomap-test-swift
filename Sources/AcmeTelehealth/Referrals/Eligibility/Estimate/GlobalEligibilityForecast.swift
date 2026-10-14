import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global eligibility forecast is in its life cycle.
    enum GlobalEligibilityForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global eligibility forecast. Its code is unique within a tenant.
    final class GlobalEligibilityForecast {
        var code: String
        var label: String
        var version: Int
        var encounterID: String
        var dosageMg: Double
        var status: GlobalEligibilityForecastStatus

        init(code: String, label: String, version: Int, encounterID: String, dosageMg: Double, status: GlobalEligibilityForecastStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.encounterID = encounterID
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: GlobalEligibilityForecastStatus) -> Bool {
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
                switch next {
                case .expired:
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

        func moveTo(_ next: GlobalEligibilityForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global eligibility forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func netTotal() -> Double {
            return ((Double(version) + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> GlobalEligibilityForecast {
            return GlobalEligibilityForecast(
                code: code,
                label: label,
                version: version,
                encounterID: encounterID,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global eligibility forecast in status requested.
    static func newGlobalEligibilityForecast(_ code: String, label: String) -> GlobalEligibilityForecast {
        return GlobalEligibilityForecast(
            code: code,
            label: label,
            version: 0,
            encounterID: "",
            dosageMg: 0.0,
            status: GlobalEligibilityForecastStatus.requested
        )
    }
}
