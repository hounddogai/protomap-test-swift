import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback care protocol mapping must pass. Check returns its problems, or none.
    protocol FallbackCareProtocolMappingRule {
        func check(_ item: FallbackCareProtocolMapping) -> [String]
    }

    final class FallbackCareProtocolMappingCostRangeRule: FallbackCareProtocolMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackCareProtocolMapping) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolMappingRequiredCodeRule: FallbackCareProtocolMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackCareProtocolMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackCareProtocolMappingCodeLengthRule: FallbackCareProtocolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackCareProtocolMappingNameLengthRule: FallbackCareProtocolMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackCareProtocolMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback care protocol mapping.
    final class FallbackCareProtocolMappingValidator {
        var rules: [any FallbackCareProtocolMappingRule]

        init(rules: [any FallbackCareProtocolMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackCareProtocolMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackCareProtocolMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackCareProtocolMapping]) -> [String: [String]] {
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

    static func defaultFallbackCareProtocolMappingValidator() -> FallbackCareProtocolMappingValidator {
        return FallbackCareProtocolMappingValidator(
            rules: [
                FallbackCareProtocolMappingCostRangeRule(min: 0.8, max: 4159.5),
                FallbackCareProtocolMappingRequiredCodeRule(message: "fallback care protocol mapping needs a value"),
                FallbackCareProtocolMappingCodeLengthRule(maxLength: 16),
                FallbackCareProtocolMappingNameLengthRule(maxLength: 64),
            ]
        )
    }
}
