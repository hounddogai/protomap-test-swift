import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a manual program override is in its life cycle.
    enum ManualProgramOverrideStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One manual program override, with what the planners need to act on it.
    final class ManualProgramOverride {
        var code: String
        var name: String
        var allergy: String
        var locale: String
        var ward: String
        var quantity: Int
        var status: ManualProgramOverrideStatus

        init(code: String, name: String, allergy: String, locale: String, ward: String, quantity: Int, status: ManualProgramOverrideStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.locale = locale
            self.ward = ward
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

        func canMoveTo(_ next: ManualProgramOverrideStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ManualProgramOverrideStatus.ready
            case .ready:
                return next == ManualProgramOverrideStatus.draining
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

        func moveTo(_ next: ManualProgramOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual program override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ManualProgramOverride {
            return ManualProgramOverride(
                code: code,
                name: name,
                allergy: allergy,
                locale: locale,
                ward: ward,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a manual program override in status idle.
    static func newManualProgramOverride(_ code: String, name: String) -> ManualProgramOverride {
        return ManualProgramOverride(
            code: code,
            name: name,
            allergy: "",
            locale: "",
            ward: "",
            quantity: 0,
            status: ManualProgramOverrideStatus.idle
        )
    }
}
