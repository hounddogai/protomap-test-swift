import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure mapping is in its life cycle.
    enum DisclosureMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a disclosure mapping and its current status.
    final class DisclosureMapping {
        var code: String
        var title: String
        var source: String
        var segment: String
        var pinned: Bool
        var quantity: Int
        var status: DisclosureMappingStatus

        init(code: String, title: String, source: String, segment: String, pinned: Bool, quantity: Int, status: DisclosureMappingStatus) {
            self.code = code
            self.title = title
            self.source = source
            self.segment = segment
            self.pinned = pinned
            self.quantity = quantity
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

        func canMoveTo(_ next: DisclosureMappingStatus) -> Bool {
            switch status {
            case .idle:
                return next == DisclosureMappingStatus.ready
            case .warming:
                return next == DisclosureMappingStatus.stopped
            case .ready:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: DisclosureMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("disclosure mapping") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> DisclosureMapping {
            return DisclosureMapping(
                code: code,
                title: title,
                source: source,
                segment: segment,
                pinned: pinned,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a disclosure mapping in status idle.
    static func newDisclosureMapping(_ code: String, title: String) -> DisclosureMapping {
        return DisclosureMapping(
            code: code,
            title: title,
            source: "",
            segment: "",
            pinned: false,
            quantity: 0,
            status: DisclosureMappingStatus.idle
        )
    }
}
