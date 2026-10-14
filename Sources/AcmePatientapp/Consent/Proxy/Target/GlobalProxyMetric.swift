import AcmePlatform
import Foundation

extension Consent {
    /// Where a global proxy metric is in its life cycle.
    enum GlobalProxyMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A global proxy metric. Its code is unique within a tenant.
    final class GlobalProxyMetric {
        var code: String
        var label: String
        var floorValue: Double
        var attempts: Int
        var contactEmail: String
        var payer: String
        var externalRef: String
        var status: GlobalProxyMetricStatus

        init(code: String, label: String, floorValue: Double, attempts: Int, contactEmail: String, payer: String, externalRef: String, status: GlobalProxyMetricStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.attempts = attempts
            self.contactEmail = contactEmail
            self.payer = payer
            self.externalRef = externalRef
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

        func canMoveTo(_ next: GlobalProxyMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == GlobalProxyMetricStatus.revoked
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

        func moveTo(_ next: GlobalProxyMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global proxy metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return ((floorValue - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalProxyMetric {
            return GlobalProxyMetric(
                code: code,
                label: label,
                floorValue: floorValue,
                attempts: attempts,
                contactEmail: contactEmail,
                payer: payer,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global proxy metric in status requested.
    static func newGlobalProxyMetric(_ code: String, label: String) -> GlobalProxyMetric {
        return GlobalProxyMetric(
            code: code,
            label: label,
            floorValue: 0.0,
            attempts: 0,
            contactEmail: "",
            payer: "",
            externalRef: "",
            status: GlobalProxyMetricStatus.requested
        )
    }
}
