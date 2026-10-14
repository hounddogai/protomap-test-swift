import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending courier window is in its life cycle.
    enum PendingCourierWindowStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a pending courier window and its current status.
    final class PendingCourierWindow {
        var code: String
        var name: String
        var retries: Int
        var attributes: [String: String]
        var locale: String
        var unit: String
        var status: PendingCourierWindowStatus

        init(code: String, name: String, retries: Int, attributes: [String: String], locale: String, unit: String, status: PendingCourierWindowStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.attributes = attributes
            self.locale = locale
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PendingCourierWindowStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == PendingCourierWindowStatus.active || next == PendingCourierWindowStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PendingCourierWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending courier window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func measuredValue() -> Double {
            return Double(retries)
        }

        func copyValue() -> PendingCourierWindow {
            return PendingCourierWindow(
                code: code,
                name: name,
                retries: retries,
                attributes: attributes,
                locale: locale,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a pending courier window in status draft.
    static func newPendingCourierWindow(_ code: String, name: String) -> PendingCourierWindow {
        return PendingCourierWindow(
            code: code,
            name: name,
            retries: 0,
            attributes: [:],
            locale: "",
            unit: "",
            status: PendingCourierWindowStatus.draft
        )
    }
}
