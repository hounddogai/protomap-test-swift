import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness variance must pass. Check returns its problems, or none.
    protocol WitnessVarianceRule {
        func check(_ item: WitnessVariance) -> [String]
    }

    final class WitnessVarianceAllowedTimezoneRule: WitnessVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is out of range"]
            }
            return []
        }
    }

    final class WitnessVarianceRequiredLabelRule: WitnessVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessVarianceEndsAtRangeRule: WitnessVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessVariance) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessVarianceCodeLengthRule: WitnessVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness variance.
    final class WitnessVarianceValidator {
        var rules: [any WitnessVarianceRule]

        init(rules: [any WitnessVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessVariance) -> [String] {
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

        func requireValid(_ item: WitnessVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessVariance]) -> [String: [String]] {
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

    static func defaultWitnessVarianceValidator() -> WitnessVarianceValidator {
        return WitnessVarianceValidator(
            rules: [
                WitnessVarianceAllowedTimezoneRule(allowed: ["lenient"]),
                WitnessVarianceRequiredLabelRule(message: "witness variance needs a value"),
                WitnessVarianceEndsAtRangeRule(min: 32, max: 1000),
                WitnessVarianceCodeLengthRule(maxLength: 255),
            ]
        )
    }
}
