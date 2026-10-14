import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a primary denial rollup is in its life cycle.
    enum PrimaryDenialRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a primary denial rollup and its current status.
    final class PrimaryDenialRollup {
        var code: String
        var label: String
        var phone: String
        var limit: Int
        var durationMinutes: Int
        var title: String
        var discount: Double
        var quantity: Int
        var status: PrimaryDenialRollupStatus

        init(code: String, label: String, phone: String, limit: Int, durationMinutes: Int, title: String, discount: Double, quantity: Int, status: PrimaryDenialRollupStatus) {
            self.code = code
            self.label = label
            self.phone = phone
            self.limit = limit
            self.durationMinutes = durationMinutes
            self.title = title
            self.discount = discount
            self.quantity = quantity
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

        func canMoveTo(_ next: PrimaryDenialRollupStatus) -> Bool {
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
                return next == PrimaryDenialRollupStatus.revoked
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

        func moveTo(_ next: PrimaryDenialRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary denial rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(durationMinutes) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryDenialRollup {
            return PrimaryDenialRollup(
                code: code,
                label: label,
                phone: phone,
                limit: limit,
                durationMinutes: durationMinutes,
                title: title,
                discount: discount,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a primary denial rollup in status requested.
    static func newPrimaryDenialRollup(_ code: String, label: String) -> PrimaryDenialRollup {
        return PrimaryDenialRollup(
            code: code,
            label: label,
            phone: "",
            limit: 0,
            durationMinutes: 0,
            title: "",
            discount: 0.0,
            quantity: 0,
            status: PrimaryDenialRollupStatus.requested
        )
    }
}
