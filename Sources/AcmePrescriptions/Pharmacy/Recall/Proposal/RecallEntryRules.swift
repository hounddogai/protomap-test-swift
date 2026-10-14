import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall entry must pass. Check returns its problems, or none.
    protocol RecallEntryRule {
        func check(_ item: RecallEntry) -> [String]
    }

    final class RecallEntryRequiredCodeRule: RecallEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallEntryArchivedGuardRule: RecallEntryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RecallEntry) -> [String] {
            if item.archived && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class RecallEntryAllowedContactEmailRule: RecallEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is above maximum"]
            }
            return []
        }
    }

    final class RecallEntryMarginRangeRule: RecallEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RecallEntry) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall entry.
    final class RecallEntryValidator {
        var rules: [any RecallEntryRule]

        init(rules: [any RecallEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallEntry]) -> [String: [String]] {
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

    static func defaultRecallEntryValidator() -> RecallEntryValidator {
        return RecallEntryValidator(
            rules: [
                RecallEntryRequiredCodeRule(message: "recall entry needs this field"),
                RecallEntryArchivedGuardRule(limit: 9.0),
                RecallEntryAllowedContactEmailRule(allowed: []),
                RecallEntryMarginRangeRule(min: 8.1, max: 1566.0),
            ]
        )
    }
}
