import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict recall entry must pass. Check returns its problems, or none.
    protocol StrictRecallEntryRule {
        func check(_ item: StrictRecallEntry) -> [String]
    }

    final class StrictRecallEntryAllowedCategoryRule: StrictRecallEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictRecallEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.category)) {
                return ["category \(item.category) is too long"]
            }
            return []
        }
    }

    final class StrictRecallEntryRequiredCodeRule: StrictRecallEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictRecallEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictRecallEntryExpiresAtRangeRule: StrictRecallEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictRecallEntry) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict recall entry.
    final class StrictRecallEntryValidator {
        var rules: [any StrictRecallEntryRule]

        init(rules: [any StrictRecallEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictRecallEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictRecallEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictRecallEntry]) -> [String: [String]] {
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

    static func defaultStrictRecallEntryValidator() -> StrictRecallEntryValidator {
        return StrictRecallEntryValidator(
            rules: [
                StrictRecallEntryAllowedCategoryRule(allowed: []),
                StrictRecallEntryRequiredCodeRule(message: "strict recall entry needs an entry"),
                StrictRecallEntryExpiresAtRangeRule(min: 32, max: 255),
            ]
        )
    }
}
