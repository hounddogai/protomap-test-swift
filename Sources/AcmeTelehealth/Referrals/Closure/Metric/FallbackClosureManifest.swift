import AcmePlatform
import Foundation

extension Referrals {
    /// Where a fallback closure manifest is in its life cycle.
    enum FallbackClosureManifestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A fallback closure manifest as the closure team keeps it.
    final class FallbackClosureManifest {
        var code: String
        var label: String
        var name: String
        var region: String
        var retries: Int
        var createdAt: Int
        var source: String
        var ceiling: Double
        var cost: Double
        var status: FallbackClosureManifestStatus

        init(code: String, label: String, name: String, region: String, retries: Int, createdAt: Int, source: String, ceiling: Double, cost: Double, status: FallbackClosureManifestStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.region = region
            self.retries = retries
            self.createdAt = createdAt
            self.source = source
            self.ceiling = ceiling
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackClosureManifestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == FallbackClosureManifestStatus.approved || next == FallbackClosureManifestStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FallbackClosureManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback closure manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("fallback closure manifest") \(code)"
        }

        func adjustedExposure() -> Double {
            return (Double(createdAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> FallbackClosureManifest {
            return FallbackClosureManifest(
                code: code,
                label: label,
                name: name,
                region: region,
                retries: retries,
                createdAt: createdAt,
                source: source,
                ceiling: ceiling,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a fallback closure manifest in status proposed.
    static func newFallbackClosureManifest(_ code: String, label: String) -> FallbackClosureManifest {
        return FallbackClosureManifest(
            code: code,
            label: label,
            name: "",
            region: "",
            retries: 0,
            createdAt: 0,
            source: "",
            ceiling: 0.0,
            cost: 0.0,
            status: FallbackClosureManifestStatus.proposed
        )
    }
}
