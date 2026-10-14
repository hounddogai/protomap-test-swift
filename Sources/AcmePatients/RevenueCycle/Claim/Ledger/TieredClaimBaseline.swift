import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered claim baseline is in its life cycle.
    enum TieredClaimBaselineStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered claim baseline as the claim team keeps it.
    final class TieredClaimBaseline {
        var code: String
        var label: String
        var ceiling: Double
        var country: String
        var weight: Double
        var rate: Double
        var ownerID: String
        var status: TieredClaimBaselineStatus

        init(code: String, label: String, ceiling: Double, country: String, weight: Double, rate: Double, ownerID: String, status: TieredClaimBaselineStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.country = country
            self.weight = weight
            self.rate = rate
            self.ownerID = ownerID
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

        func canMoveTo(_ next: TieredClaimBaselineStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredClaimBaselineStatus.granted || next == TieredClaimBaselineStatus.revoked
            case .granted:
                return next == TieredClaimBaselineStatus.revoked || next == TieredClaimBaselineStatus.expired
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

        func moveTo(_ next: TieredClaimBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered claim baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return ((weight + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> TieredClaimBaseline {
            return TieredClaimBaseline(
                code: code,
                label: label,
                ceiling: ceiling,
                country: country,
                weight: weight,
                rate: rate,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a tiered claim baseline in status requested.
    static func newTieredClaimBaseline(_ code: String, label: String) -> TieredClaimBaseline {
        return TieredClaimBaseline(
            code: code,
            label: label,
            ceiling: 0.0,
            country: "",
            weight: 0.0,
            rate: 0.0,
            ownerID: "",
            status: TieredClaimBaselineStatus.requested
        )
    }
}
