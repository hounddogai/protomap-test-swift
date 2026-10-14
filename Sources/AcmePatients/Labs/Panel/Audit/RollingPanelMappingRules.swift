import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling panel mapping must pass. Check returns its problems, or none.
    protocol RollingPanelMappingRule {
        func check(_ item: RollingPanelMapping) -> [String]
    }

    final class RollingPanelMappingAllowedTimezoneRule: RollingPanelMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingPanelMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is stale"]
            }
            return []
        }
    }

    final class RollingPanelMappingRequiredCodeRule: RollingPanelMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPanelMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingPanelMappingRetriesRangeRule: RollingPanelMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingPanelMapping) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingPanelMappingRequiredCountryRule: RollingPanelMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPanelMapping) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingPanelMappingCodeLengthRule: RollingPanelMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPanelMappingCountryLengthRule: RollingPanelMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelMapping) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling panel mapping.
    final class RollingPanelMappingValidator {
        var rules: [any RollingPanelMappingRule]

        init(rules: [any RollingPanelMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPanelMapping) -> [String] {
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

        func requireValid(_ item: RollingPanelMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPanelMapping]) -> [String: [String]] {
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

    static func defaultRollingPanelMappingValidator() -> RollingPanelMappingValidator {
        return RollingPanelMappingValidator(
            rules: [
                RollingPanelMappingAllowedTimezoneRule(allowed: ["capped", "weighted", "rolling"]),
                RollingPanelMappingRequiredCodeRule(message: "rolling panel mapping needs an entry"),
                RollingPanelMappingRetriesRangeRule(min: 16, max: 64),
                RollingPanelMappingRequiredCountryRule(message: "rolling panel mapping needs an entry"),
                RollingPanelMappingCodeLengthRule(maxLength: 64),
                RollingPanelMappingCountryLengthRule(maxLength: 120),
            ]
        )
    }
}
