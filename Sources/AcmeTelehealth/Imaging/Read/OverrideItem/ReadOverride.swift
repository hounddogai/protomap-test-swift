import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read override is in its life cycle.
    enum ReadOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One read override, with what the planners need to act on it.
    final class ReadOverride {
        var code: String
        var label: String
        var facility: String
        var title: String
        var attributes: [String: String]
        var amount: Double
        var status: ReadOverrideStatus

        init(code: String, label: String, facility: String, title: String, attributes: [String: String], amount: Double, status: ReadOverrideStatus) {
            self.code = code
            self.label = label
            self.facility = facility
            self.title = title
            self.attributes = attributes
            self.amount = amount
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

        func canMoveTo(_ next: ReadOverrideStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == ReadOverrideStatus.active || next == ReadOverrideStatus.closed
            case .active:
                return next == ReadOverrideStatus.suspended || next == ReadOverrideStatus.closed
            case .suspended:
                return next == ReadOverrideStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
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
            return amount
        }

        func copyValue() -> ReadOverride {
            return ReadOverride(
                code: code,
                label: label,
                facility: facility,
                title: title,
                attributes: attributes,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a read override in status draft.
    static func newReadOverride(_ code: String, label: String) -> ReadOverride {
        return ReadOverride(
            code: code,
            label: label,
            facility: "",
            title: "",
            attributes: [:],
            amount: 0.0,
            status: ReadOverrideStatus.draft
        )
    }
}
