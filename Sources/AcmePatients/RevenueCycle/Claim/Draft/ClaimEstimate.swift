import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a claim estimate is in its life cycle.
    enum ClaimEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A claim estimate as the claim team keeps it.
    final class ClaimEstimate {
        var code: String
        var title: String
        var unit: String
        var expiresAt: Int
        var retries: Int
        var capacity: Int
        var budget: Double
        var status: ClaimEstimateStatus

        init(code: String, title: String, unit: String, expiresAt: Int, retries: Int, capacity: Int, budget: Double, status: ClaimEstimateStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.expiresAt = expiresAt
            self.retries = retries
            self.capacity = capacity
            self.budget = budget
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

        func canMoveTo(_ next: ClaimEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == ClaimEstimateStatus.revoked
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

        func moveTo(_ next: ClaimEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("claim estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("claim estimate") \(code)"
        }

        func adjustedValue() -> Double {
            return ((budget + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ClaimEstimate {
            return ClaimEstimate(
                code: code,
                title: title,
                unit: unit,
                expiresAt: expiresAt,
                retries: retries,
                capacity: capacity,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a claim estimate in status requested.
    static func newClaimEstimate(_ code: String, title: String) -> ClaimEstimate {
        return ClaimEstimate(
            code: code,
            title: title,
            unit: "",
            expiresAt: 0,
            retries: 0,
            capacity: 0,
            budget: 0.0,
            status: ClaimEstimateStatus.requested
        )
    }
}
