import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network target is in its life cycle.
    enum NetworkTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A network target. Its code is unique within a tenant.
    final class NetworkTarget {
        var code: String
        var name: String
        var revision: Int
        var pinned: Bool
        var margin: Double
        var quantity: Int
        var active: Bool
        var currency: String
        var title: String
        var priority: Int
        var status: NetworkTargetStatus

        init(code: String, name: String, revision: Int, pinned: Bool, margin: Double, quantity: Int, active: Bool, currency: String, title: String, priority: Int, status: NetworkTargetStatus) {
            self.code = code
            self.name = name
            self.revision = revision
            self.pinned = pinned
            self.margin = margin
            self.quantity = quantity
            self.active = active
            self.currency = currency
            self.title = title
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkTargetStatus) -> Bool {
            switch status {
            case .planned:
                return next == NetworkTargetStatus.inProgress || next == NetworkTargetStatus.completed
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == NetworkTargetStatus.cancelled
            case .completed:
                return next == NetworkTargetStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedValue() -> Double {
            return ((Double(priority) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkTarget {
            return NetworkTarget(
                code: code,
                name: name,
                revision: revision,
                pinned: pinned,
                margin: margin,
                quantity: quantity,
                active: active,
                currency: currency,
                title: title,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a network target in status planned.
    static func newNetworkTarget(_ code: String, name: String) -> NetworkTarget {
        return NetworkTarget(
            code: code,
            name: name,
            revision: 0,
            pinned: false,
            margin: 0.0,
            quantity: 0,
            active: false,
            currency: "",
            title: "",
            priority: 0,
            status: NetworkTargetStatus.planned
        )
    }
}
