import AcmePlatform
import Foundation

extension Consent {
    /// Where a fallback revocation snapshot is in its life cycle.
    enum FallbackRevocationSnapshotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A fallback revocation snapshot. Its code is unique within a tenant.
    final class FallbackRevocationSnapshot {
        var code: String
        var title: String
        var payer: String
        var quantity: Int
        var discount: Double
        var tags: [String]
        var status: FallbackRevocationSnapshotStatus

        init(code: String, title: String, payer: String, quantity: Int, discount: Double, tags: [String], status: FallbackRevocationSnapshotStatus) {
            self.code = code
            self.title = title
            self.payer = payer
            self.quantity = quantity
            self.discount = discount
            self.tags = tags
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

        func canMoveTo(_ next: FallbackRevocationSnapshotStatus) -> Bool {
            switch status {
            case .idle:
                return next == FallbackRevocationSnapshotStatus.ready
            case .warming:
                return next == FallbackRevocationSnapshotStatus.stopped
            case .ready:
                return next == FallbackRevocationSnapshotStatus.draining || next == FallbackRevocationSnapshotStatus.stopped
            case .draining:
                return next == FallbackRevocationSnapshotStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FallbackRevocationSnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback revocation snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedTotal() -> Double {
            return ((Double(quantity) - discount) * 100).rounded() / 100
        }

        func copyValue() -> FallbackRevocationSnapshot {
            return FallbackRevocationSnapshot(
                code: code,
                title: title,
                payer: payer,
                quantity: quantity,
                discount: discount,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a fallback revocation snapshot in status idle.
    static func newFallbackRevocationSnapshot(_ code: String, title: String) -> FallbackRevocationSnapshot {
        return FallbackRevocationSnapshot(
            code: code,
            title: title,
            payer: "",
            quantity: 0,
            discount: 0.0,
            tags: [],
            status: FallbackRevocationSnapshotStatus.idle
        )
    }
}
