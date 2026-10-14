import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted credential profile is in its life cycle.
    enum WeightedCredentialProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted credential profile. Its code is unique within a tenant.
    final class WeightedCredentialProfile {
        var code: String
        var name: String
        var floorValue: Double
        var limit: Int
        var quantity: Int
        var amount: Double
        var status: WeightedCredentialProfileStatus

        init(code: String, name: String, floorValue: Double, limit: Int, quantity: Int, amount: Double, status: WeightedCredentialProfileStatus) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.limit = limit
            self.quantity = quantity
            self.amount = amount
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

        func canMoveTo(_ next: WeightedCredentialProfileStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedCredentialProfileStatus.granted || next == WeightedCredentialProfileStatus.expired
            case .granted:
                return next == WeightedCredentialProfileStatus.revoked || next == WeightedCredentialProfileStatus.expired
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

        func moveTo(_ next: WeightedCredentialProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted credential profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("weighted credential profile") \(code)"
        }

        func weightedLoad() -> Double {
            return ((floorValue + amount) * 100).rounded() / 100
        }

        func copyValue() -> WeightedCredentialProfile {
            return WeightedCredentialProfile(
                code: code,
                name: name,
                floorValue: floorValue,
                limit: limit,
                quantity: quantity,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a weighted credential profile in status requested.
    static func newWeightedCredentialProfile(_ code: String, name: String) -> WeightedCredentialProfile {
        return WeightedCredentialProfile(
            code: code,
            name: name,
            floorValue: 0.0,
            limit: 0,
            quantity: 0,
            amount: 0.0,
            status: WeightedCredentialProfileStatus.requested
        )
    }
}
