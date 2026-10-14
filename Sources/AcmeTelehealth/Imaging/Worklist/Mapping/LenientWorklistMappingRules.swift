import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a lenient worklist mapping must pass. Check returns its problems, or none.
    protocol LenientWorklistMappingRule {
        func check(_ item: LenientWorklistMapping) -> [String]
    }

    final class LenientWorklistMappingRequiredNameRule: LenientWorklistMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientWorklistMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientWorklistMappingCodePrefixRule: LenientWorklistMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientWorklistMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientWorklistMappingMaximumRangeRule: LenientWorklistMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientWorklistMapping) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient worklist mapping.
    final class LenientWorklistMappingValidator {
        var rules: [any LenientWorklistMappingRule]

        init(rules: [any LenientWorklistMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientWorklistMapping) -> [String] {
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

        func requireValid(_ item: LenientWorklistMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientWorklistMapping]) -> [String: [String]] {
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

    static func defaultLenientWorklistMappingValidator() -> LenientWorklistMappingValidator {
        return LenientWorklistMappingValidator(
            rules: [
                LenientWorklistMappingRequiredNameRule(message: "lenient worklist mapping needs an entry"),
                LenientWorklistMappingCodePrefixRule(prefix: "Q"),
                LenientWorklistMappingMaximumRangeRule(min: 4.7, max: 78.9),
            ]
        )
    }
}
