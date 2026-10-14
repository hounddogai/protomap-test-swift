import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global charge mapping must pass. Check returns its problems, or none.
    protocol GlobalChargeMappingRule {
        func check(_ item: GlobalChargeMapping) -> [String]
    }

    final class GlobalChargeMappingAttemptsRangeRule: GlobalChargeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalChargeMapping) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalChargeMappingLocaleLengthRule: GlobalChargeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalChargeMapping) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalChargeMappingRetriesRangeRule: GlobalChargeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalChargeMapping) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalChargeMappingCodeLengthRule: GlobalChargeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalChargeMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalChargeMappingAllowedCodeRule: GlobalChargeMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalChargeMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class GlobalChargeMappingRequiredCodeRule: GlobalChargeMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalChargeMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global charge mapping.
    final class GlobalChargeMappingValidator {
        var rules: [any GlobalChargeMappingRule]

        init(rules: [any GlobalChargeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalChargeMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalChargeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalChargeMapping]) -> [String: [String]] {
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

    static func defaultGlobalChargeMappingValidator() -> GlobalChargeMappingValidator {
        return GlobalChargeMappingValidator(
            rules: [
                GlobalChargeMappingAttemptsRangeRule(min: 16, max: 120),
                GlobalChargeMappingLocaleLengthRule(maxLength: 80),
                GlobalChargeMappingRetriesRangeRule(min: 32, max: 3600),
                GlobalChargeMappingCodeLengthRule(maxLength: 80),
                GlobalChargeMappingAllowedCodeRule(allowed: []),
                GlobalChargeMappingRequiredCodeRule(message: "global charge mapping needs a value"),
            ]
        )
    }
}
