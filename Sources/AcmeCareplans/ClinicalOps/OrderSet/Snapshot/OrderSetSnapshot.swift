import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set snapshot is in its life cycle.
    enum OrderSetSnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A order set snapshot. Its code is unique within a tenant.
    final class OrderSetSnapshot {
        var code: String
        var name: String
        var active: Bool
        var pinned: Bool
        var tags: [String]
        var quantity: Int
        var acuity: Int
        var status: OrderSetSnapshotStatus

        init(code: String, name: String, active: Bool, pinned: Bool, tags: [String], quantity: Int, acuity: Int, status: OrderSetSnapshotStatus) {
            self.code = code
            self.name = name
            self.active = active
            self.pinned = pinned
            self.tags = tags
            self.quantity = quantity
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: OrderSetSnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == OrderSetSnapshotStatus.running
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == OrderSetSnapshotStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: OrderSetSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("order set snapshot") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((Double(quantity) + Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetSnapshot {
            return OrderSetSnapshot(
                code: code,
                name: name,
                active: active,
                pinned: pinned,
                tags: tags,
                quantity: quantity,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a order set snapshot in status new.
    static func newOrderSetSnapshot(_ code: String, name: String) -> OrderSetSnapshot {
        return OrderSetSnapshot(
            code: code,
            name: name,
            active: false,
            pinned: false,
            tags: [],
            quantity: 0,
            acuity: 0,
            status: OrderSetSnapshotStatus.new
        )
    }
}
