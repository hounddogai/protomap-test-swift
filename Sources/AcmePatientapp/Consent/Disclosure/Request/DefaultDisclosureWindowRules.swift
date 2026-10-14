import AcmePlatform
import Foundation

extension Consent {
    /// A rule a default disclosure window must pass. Check returns its problems, or none.
    protocol DefaultDisclosureWindowRule {
        func check(_ item: DefaultDisclosureWindow) -> [String]
    }

    final class DefaultDisclosureWindowArchivedGuardRule: DefaultDisclosureWindowRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultDisclosureWindow) -> [String] {
            if item.archived && (item.capacity > limit) {
                return ["capacity \(item.capacity) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class DefaultDisclosureWindowCapacityRangeRule: DefaultDisclosureWindowRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDisclosureWindow) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultDisclosureWindowCodePrefixRule: DefaultDisclosureWindowRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultDisclosureWindow) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultDisclosureWindowRequiredCategoryRule: DefaultDisclosureWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDisclosureWindow) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default disclosure window.
    final class DefaultDisclosureWindowValidator {
        var rules: [any DefaultDisclosureWindowRule]

        init(rules: [any DefaultDisclosureWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDisclosureWindow) -> [String] {
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

        func requireValid(_ item: DefaultDisclosureWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDisclosureWindow]) -> [String: [String]] {
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

    static func defaultDefaultDisclosureWindowValidator() -> DefaultDisclosureWindowValidator {
        return DefaultDisclosureWindowValidator(
            rules: [
                DefaultDisclosureWindowArchivedGuardRule(limit: 3600),
                DefaultDisclosureWindowCapacityRangeRule(min: 16, max: 32),
                DefaultDisclosureWindowCodePrefixRule(prefix: "REF"),
                DefaultDisclosureWindowRequiredCategoryRule(message: "default disclosure window needs this field"),
            ]
        )
    }
}
