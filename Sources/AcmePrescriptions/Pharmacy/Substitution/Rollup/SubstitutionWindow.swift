import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution window is in its life cycle.
    enum SubstitutionWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A substitution window. Its code is unique within a tenant.
    final class SubstitutionWindow {
        var code: String
        var name: String
        var title: String
        var active: Bool
        var category: String
        var timezone: String
        var quantity: Int
        var checksum: String
        var phone: String
        var status: SubstitutionWindowStatus

        init(code: String, name: String, title: String, active: Bool, category: String, timezone: String, quantity: Int, checksum: String, phone: String, status: SubstitutionWindowStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.active = active
            self.category = category
            self.timezone = timezone
            self.quantity = quantity
            self.checksum = checksum
            self.phone = phone
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

        func canMoveTo(_ next: SubstitutionWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == SubstitutionWindowStatus.draining
            case .warming:
                return next == SubstitutionWindowStatus.ready || next == SubstitutionWindowStatus.stopped
            case .ready:
                return next == SubstitutionWindowStatus.stopped
            case .draining:
                return next == SubstitutionWindowStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SubstitutionWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> SubstitutionWindow {
            return SubstitutionWindow(
                code: code,
                name: name,
                title: title,
                active: active,
                category: category,
                timezone: timezone,
                quantity: quantity,
                checksum: checksum,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a substitution window in status idle.
    static func newSubstitutionWindow(_ code: String, name: String) -> SubstitutionWindow {
        return SubstitutionWindow(
            code: code,
            name: name,
            title: "",
            active: false,
            category: "",
            timezone: "",
            quantity: 0,
            checksum: "",
            phone: "",
            status: SubstitutionWindowStatus.idle
        )
    }
}
