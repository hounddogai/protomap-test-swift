import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback worklist group must pass. Check returns its problems, or none.
    protocol FallbackWorklistGroupRule {
        func check(_ item: FallbackWorklistGroup) -> [String]
    }

    final class FallbackWorklistGroupSequenceRangeRule: FallbackWorklistGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackWorklistGroup) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackWorklistGroupNameLengthRule: FallbackWorklistGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackWorklistGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackWorklistGroupAllowedNameRule: FallbackWorklistGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackWorklistGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class FallbackWorklistGroupRequiredUnitRule: FallbackWorklistGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackWorklistGroup) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback worklist group.
    final class FallbackWorklistGroupValidator {
        var rules: [any FallbackWorklistGroupRule]

        init(rules: [any FallbackWorklistGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackWorklistGroup) -> [String] {
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

        func requireValid(_ item: FallbackWorklistGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackWorklistGroup]) -> [String: [String]] {
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

    static func defaultFallbackWorklistGroupValidator() -> FallbackWorklistGroupValidator {
        return FallbackWorklistGroupValidator(
            rules: [
                FallbackWorklistGroupSequenceRangeRule(min: 1000, max: 1000),
                FallbackWorklistGroupNameLengthRule(maxLength: 1000),
                FallbackWorklistGroupAllowedNameRule(allowed: ["global", "tiered"]),
                FallbackWorklistGroupRequiredUnitRule(message: "fallback worklist group needs a value"),
            ]
        )
    }
}
