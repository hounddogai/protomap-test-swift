import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory notice must pass. Check returns its problems, or none.
    protocol InventoryNoticeRule {
        func check(_ item: InventoryNotice) -> [String]
    }

    final class InventoryNoticeCurrencyLengthRule: InventoryNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryNotice) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryNoticeRequiredCurrencyRule: InventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryNotice) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryNoticeRequiredTitleRule: InventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryNoticeRequiredLabelRule: InventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryNoticeAllowedTitleRule: InventoryNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class InventoryNoticeApprovedGuardRule: InventoryNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: InventoryNotice) -> [String] {
            if item.approved && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory notice.
    final class InventoryNoticeValidator {
        var rules: [any InventoryNoticeRule]

        init(rules: [any InventoryNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: InventoryNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryNotice]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultInventoryNoticeValidator() -> InventoryNoticeValidator {
        return InventoryNoticeValidator(
            rules: [
                InventoryNoticeCurrencyLengthRule(maxLength: 80),
                InventoryNoticeRequiredCurrencyRule(message: "inventory notice needs an entry"),
                InventoryNoticeRequiredTitleRule(message: "inventory notice needs an entry"),
                InventoryNoticeRequiredLabelRule(message: "inventory notice needs an entry"),
                InventoryNoticeAllowedTitleRule(allowed: []),
                InventoryNoticeApprovedGuardRule(limit: 64),
            ]
        )
    }
}
