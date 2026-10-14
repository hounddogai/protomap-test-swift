import AcmePlatform
import Foundation

extension Consent {
    /// Where a regional proxy manifest is in its life cycle.
    enum RegionalProxyManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A regional proxy manifest. Its code is unique within a tenant.
    final class RegionalProxyManifest {
        var code: String
        var label: String
        var discount: Double
        var dosageMg: Double
        var title: String
        var summary: String
        var country: String
        var status: RegionalProxyManifestStatus

        init(code: String, label: String, discount: Double, dosageMg: Double, title: String, summary: String, country: String, status: RegionalProxyManifestStatus) {
            self.code = code
            self.label = label
            self.discount = discount
            self.dosageMg = dosageMg
            self.title = title
            self.summary = summary
            self.country = country
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

        func canMoveTo(_ next: RegionalProxyManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalProxyManifestStatus.retired
            case .validated:
                return next == RegionalProxyManifestStatus.published || next == RegionalProxyManifestStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalProxyManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional proxy manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return (dosageMg * discount * 100).rounded() / 100
        }

        func copyValue() -> RegionalProxyManifest {
            return RegionalProxyManifest(
                code: code,
                label: label,
                discount: discount,
                dosageMg: dosageMg,
                title: title,
                summary: summary,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional proxy manifest in status created.
    static func newRegionalProxyManifest(_ code: String, label: String) -> RegionalProxyManifest {
        return RegionalProxyManifest(
            code: code,
            label: label,
            discount: 0.0,
            dosageMg: 0.0,
            title: "",
            summary: "",
            country: "",
            status: RegionalProxyManifestStatus.created
        )
    }
}
