import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback shift mapping must pass. Check returns its problems, or none.
    protocol FallbackShiftMappingRule {
        func check(_ item: FallbackShiftMapping) -> [String]
    }

    final class FallbackShiftMappingExpiresAtRangeRule: FallbackShiftMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackShiftMapping) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackShiftMappingRequiredNameRule: FallbackShiftMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackShiftMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackShiftMappingRequiredCodeRule: FallbackShiftMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackShiftMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback shift mapping.
    final class FallbackShiftMappingValidator {
        var rules: [any FallbackShiftMappingRule]

        init(rules: [any FallbackShiftMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackShiftMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackShiftMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackShiftMapping]) -> [String: [String]] {
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

    static func defaultFallbackShiftMappingValidator() -> FallbackShiftMappingValidator {
        return FallbackShiftMappingValidator(
            rules: [
                FallbackShiftMappingExpiresAtRangeRule(min: 255, max: 86400),
                FallbackShiftMappingRequiredNameRule(message: "fallback shift mapping needs a value"),
                FallbackShiftMappingRequiredCodeRule(message: "fallback shift mapping needs an entry"),
            ]
        )
    }
}
