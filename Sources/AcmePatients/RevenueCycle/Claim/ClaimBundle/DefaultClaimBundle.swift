import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default claim bundle is in its life cycle.
    enum DefaultClaimBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default claim bundle as the claim team keeps it.
    final class DefaultClaimBundle {
        var code: String
        var title: String
        var quantity: Int
        var floorValue: Double
        var pinned: Bool
        var currency: String
        var status: DefaultClaimBundleStatus

        init(code: String, title: String, quantity: Int, floorValue: Double, pinned: Bool, currency: String, status: DefaultClaimBundleStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.floorValue = floorValue
            self.pinned = pinned
            self.currency = currency
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultClaimBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DefaultClaimBundleStatus.draining || next == DefaultClaimBundleStatus.stopped
            case .draining:
                return next == DefaultClaimBundleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultClaimBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default claim bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedExposure() -> Double {
            return ((floorValue + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultClaimBundle {
            return DefaultClaimBundle(
                code: code,
                title: title,
                quantity: quantity,
                floorValue: floorValue,
                pinned: pinned,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default claim bundle in status idle.
    static func newDefaultClaimBundle(_ code: String, title: String) -> DefaultClaimBundle {
        return DefaultClaimBundle(
            code: code,
            title: title,
            quantity: 0,
            floorValue: 0.0,
            pinned: false,
            currency: "",
            status: DefaultClaimBundleStatus.idle
        )
    }
}
