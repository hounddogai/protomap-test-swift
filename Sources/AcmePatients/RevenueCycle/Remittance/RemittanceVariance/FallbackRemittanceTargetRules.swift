import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback remittance target must pass. Check returns its problems, or none.
    protocol FallbackRemittanceTargetRule {
        func check(_ item: FallbackRemittanceTarget) -> [String]
    }

    final class FallbackRemittanceTargetRequiredCodeRule: FallbackRemittanceTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRemittanceTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRemittanceTargetRegionLengthRule: FallbackRemittanceTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRemittanceTarget) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRemittanceTargetCodeLengthRule: FallbackRemittanceTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRemittanceTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRemittanceTargetTitleLengthRule: FallbackRemittanceTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRemittanceTarget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRemittanceTargetAttemptsRangeRule: FallbackRemittanceTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRemittanceTarget) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackRemittanceTargetAllergyLengthRule: FallbackRemittanceTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRemittanceTarget) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback remittance target.
    final class FallbackRemittanceTargetValidator {
        var rules: [any FallbackRemittanceTargetRule]

        init(rules: [any FallbackRemittanceTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRemittanceTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRemittanceTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRemittanceTarget]) -> [String: [String]] {
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

    static func defaultFallbackRemittanceTargetValidator() -> FallbackRemittanceTargetValidator {
        return FallbackRemittanceTargetValidator(
            rules: [
                FallbackRemittanceTargetRequiredCodeRule(message: "fallback remittance target needs an entry"),
                FallbackRemittanceTargetRegionLengthRule(maxLength: 255),
                FallbackRemittanceTargetCodeLengthRule(maxLength: 86400),
                FallbackRemittanceTargetTitleLengthRule(maxLength: 80),
                FallbackRemittanceTargetAttemptsRangeRule(min: 80, max: 120),
                FallbackRemittanceTargetAllergyLengthRule(maxLength: 3600),
            ]
        )
    }
}
