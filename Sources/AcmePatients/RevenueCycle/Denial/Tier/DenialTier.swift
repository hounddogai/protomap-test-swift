import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial tier is in its life cycle.
    enum DenialTierStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A denial tier. Its code is unique within a tenant.
    final class DenialTier {
        var code: String
        var title: String
        var unit: String
        var active: Bool
        var createdAt: Int
        var currency: String
        var ceiling: Double
        var status: DenialTierStatus

        init(code: String, title: String, unit: String, active: Bool, createdAt: Int, currency: String, ceiling: Double, status: DenialTierStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.active = active
            self.createdAt = createdAt
            self.currency = currency
            self.ceiling = ceiling
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

        func canMoveTo(_ next: DenialTierStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == DenialTierStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveValue() -> Double {
            return (Double(createdAt) * ceiling * 100).rounded() / 100
        }

        func copyValue() -> DenialTier {
            return DenialTier(
                code: code,
                title: title,
                unit: unit,
                active: active,
                createdAt: createdAt,
                currency: currency,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a denial tier in status requested.
    static func newDenialTier(_ code: String, title: String) -> DenialTier {
        return DenialTier(
            code: code,
            title: title,
            unit: "",
            active: false,
            createdAt: 0,
            currency: "",
            ceiling: 0.0,
            status: DenialTierStatus.requested
        )
    }
}
