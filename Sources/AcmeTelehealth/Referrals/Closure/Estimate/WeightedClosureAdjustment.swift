import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted closure adjustment is in its life cycle.
    enum WeightedClosureAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One weighted closure adjustment, with what the planners need to act on it.
    final class WeightedClosureAdjustment {
        var code: String
        var name: String
        var floorValue: Double
        var capacity: Int
        var payer: String
        var updatedAt: Int
        var country: String
        var limit: Int
        var status: WeightedClosureAdjustmentStatus

        init(code: String, name: String, floorValue: Double, capacity: Int, payer: String, updatedAt: Int, country: String, limit: Int, status: WeightedClosureAdjustmentStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.capacity = capacity
            self.payer = payer
            self.updatedAt = updatedAt
            self.country = country
            self.limit = limit
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

        func canMoveTo(_ next: WeightedClosureAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedClosureAdjustmentStatus.revoked
            case .granted:
                switch next {
                case .revoked:
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

        func moveTo(_ next: WeightedClosureAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted closure adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netExposure() -> Double {
            return (Double(capacity) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> WeightedClosureAdjustment {
            return WeightedClosureAdjustment(
                code: code,
                name: name,
                floorValue: floorValue,
                capacity: capacity,
                payer: payer,
                updatedAt: updatedAt,
                country: country,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted closure adjustment in status requested.
    static func newWeightedClosureAdjustment(_ code: String, name: String) -> WeightedClosureAdjustment {
        return WeightedClosureAdjustment(
            code: code,
            name: name,
            floorValue: 0.0,
            capacity: 0,
            payer: "",
            updatedAt: 0,
            country: "",
            limit: 0,
            status: WeightedClosureAdjustmentStatus.requested
        )
    }
}
