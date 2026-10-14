import AcmePlatform
import Foundation

extension Labs {
    /// Where a result adjustment is in its life cycle.
    enum ResultAdjustmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A result adjustment. Its code is unique within a tenant.
    final class ResultAdjustment {
        var code: String
        var name: String
        var unit: String
        var quantity: Int
        var active: Bool
        var limit: Int
        var status: ResultAdjustmentStatus

        init(code: String, name: String, unit: String, quantity: Int, active: Bool, limit: Int, status: ResultAdjustmentStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.quantity = quantity
            self.active = active
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

        func canMoveTo(_ next: ResultAdjustmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == ResultAdjustmentStatus.revoked || next == ResultAdjustmentStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ResultAdjustmentStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return ((Double(limit) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ResultAdjustment {
            return ResultAdjustment(
                code: code,
                name: name,
                unit: unit,
                quantity: quantity,
                active: active,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a result adjustment in status requested.
    static func newResultAdjustment(_ code: String, name: String) -> ResultAdjustment {
        return ResultAdjustment(
            code: code,
            name: name,
            unit: "",
            quantity: 0,
            active: false,
            limit: 0,
            status: ResultAdjustmentStatus.requested
        )
    }
}
