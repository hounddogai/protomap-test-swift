import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rolling rounding quota is in its life cycle.
    enum RollingRoundingQuotaStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling rounding quota as the rounding team keeps it.
    final class RollingRoundingQuota {
        var code: String
        var name: String
        var segment: String
        var title: String
        var quantity: Int
        var status: RollingRoundingQuotaStatus

        init(code: String, name: String, segment: String, title: String, quantity: Int, status: RollingRoundingQuotaStatus) {
            self.code = code
            self.name = name
            self.segment = segment
            self.title = title
            self.quantity = quantity
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

        func canMoveTo(_ next: RollingRoundingQuotaStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RollingRoundingQuotaStatus.approved
            case .approved:
                return next == RollingRoundingQuotaStatus.rejected
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

        func moveTo(_ next: RollingRoundingQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling rounding quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> RollingRoundingQuota {
            return RollingRoundingQuota(
                code: code,
                name: name,
                segment: segment,
                title: title,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a rolling rounding quota in status proposed.
    static func newRollingRoundingQuota(_ code: String, name: String) -> RollingRoundingQuota {
        return RollingRoundingQuota(
            code: code,
            name: name,
            segment: "",
            title: "",
            quantity: 0,
            status: RollingRoundingQuotaStatus.proposed
        )
    }
}
