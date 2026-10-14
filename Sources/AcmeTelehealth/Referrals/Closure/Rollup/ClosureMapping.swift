import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure mapping is in its life cycle.
    enum ClosureMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a closure mapping and its current status.
    final class ClosureMapping {
        var code: String
        var label: String
        var locale: String
        var pinned: Bool
        var quantity: Int
        var status: ClosureMappingStatus

        init(code: String, label: String, locale: String, pinned: Bool, quantity: Int, status: ClosureMappingStatus) {
            self.code = code
            self.label = label
            self.locale = locale
            self.pinned = pinned
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ClosureMappingStatus) -> Bool {
            switch status {
            case .created:
                return next == ClosureMappingStatus.validated
            case .validated:
                return next == ClosureMappingStatus.published
            case .published:
                return next == ClosureMappingStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("closure mapping") \(code)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ClosureMapping {
            return ClosureMapping(
                code: code,
                label: label,
                locale: locale,
                pinned: pinned,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a closure mapping in status created.
    static func newClosureMapping(_ code: String, label: String) -> ClosureMapping {
        return ClosureMapping(
            code: code,
            label: label,
            locale: "",
            pinned: false,
            quantity: 0,
            status: ClosureMappingStatus.created
        )
    }
}
