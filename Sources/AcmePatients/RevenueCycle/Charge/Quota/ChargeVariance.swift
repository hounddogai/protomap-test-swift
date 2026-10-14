import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge variance is in its life cycle.
    enum ChargeVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A charge variance. Its code is unique within a tenant.
    final class ChargeVariance {
        var code: String
        var title: String
        var threshold: Double
        var priority: Int
        var active: Bool
        var windowDays: Int
        var pinned: Bool
        var createdAt: Int
        var cost: Double
        var contactEmail: String
        var status: ChargeVarianceStatus

        init(code: String, title: String, threshold: Double, priority: Int, active: Bool, windowDays: Int, pinned: Bool, createdAt: Int, cost: Double, contactEmail: String, status: ChargeVarianceStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.priority = priority
            self.active = active
            self.windowDays = windowDays
            self.pinned = pinned
            self.createdAt = createdAt
            self.cost = cost
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ChargeVarianceStatus) -> Bool {
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
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ChargeVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedTotal() -> Double {
            return ((Double(createdAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> ChargeVariance {
            return ChargeVariance(
                code: code,
                title: title,
                threshold: threshold,
                priority: priority,
                active: active,
                windowDays: windowDays,
                pinned: pinned,
                createdAt: createdAt,
                cost: cost,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a charge variance in status requested.
    static func newChargeVariance(_ code: String, title: String) -> ChargeVariance {
        return ChargeVariance(
            code: code,
            title: title,
            threshold: 0.0,
            priority: 0,
            active: false,
            windowDays: 0,
            pinned: false,
            createdAt: 0,
            cost: 0.0,
            contactEmail: "",
            status: ChargeVarianceStatus.requested
        )
    }
}
