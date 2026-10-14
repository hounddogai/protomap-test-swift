import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional isolation baseline is in its life cycle.
    enum RegionalIsolationBaselineStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a regional isolation baseline and its current status.
    final class RegionalIsolationBaseline {
        var code: String
        var name: String
        var locale: String
        var title: String
        var description: String
        var tags: [String]
        var quantity: Int
        var status: RegionalIsolationBaselineStatus

        init(code: String, name: String, locale: String, title: String, description: String, tags: [String], quantity: Int, status: RegionalIsolationBaselineStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.title = title
            self.description = description
            self.tags = tags
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalIsolationBaselineStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RegionalIsolationBaselineStatus.approved
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == RegionalIsolationBaselineStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalIsolationBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional isolation baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional isolation baseline") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> RegionalIsolationBaseline {
            return RegionalIsolationBaseline(
                code: code,
                name: name,
                locale: locale,
                title: title,
                description: description,
                tags: tags,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a regional isolation baseline in status proposed.
    static func newRegionalIsolationBaseline(_ code: String, name: String) -> RegionalIsolationBaseline {
        return RegionalIsolationBaseline(
            code: code,
            name: name,
            locale: "",
            title: "",
            description: "",
            tags: [],
            quantity: 0,
            status: RegionalIsolationBaselineStatus.proposed
        )
    }
}
