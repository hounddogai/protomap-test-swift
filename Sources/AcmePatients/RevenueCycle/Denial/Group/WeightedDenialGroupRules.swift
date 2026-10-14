import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a weighted denial group must pass. Check returns its problems, or none.
    protocol WeightedDenialGroupRule {
        func check(_ item: WeightedDenialGroup) -> [String]
    }

    final class WeightedDenialGroupNameLengthRule: WeightedDenialGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedDenialGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedDenialGroupMaximumRangeRule: WeightedDenialGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedDenialGroup) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedDenialGroupRequiredCodeRule: WeightedDenialGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDenialGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedDenialGroupRequiredFacilityRule: WeightedDenialGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedDenialGroup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted denial group.
    final class WeightedDenialGroupValidator {
        var rules: [any WeightedDenialGroupRule]

        init(rules: [any WeightedDenialGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedDenialGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedDenialGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedDenialGroup]) -> [String: [String]] {
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

    static func defaultWeightedDenialGroupValidator() -> WeightedDenialGroupValidator {
        return WeightedDenialGroupValidator(
            rules: [
                WeightedDenialGroupNameLengthRule(maxLength: 86400),
                WeightedDenialGroupMaximumRangeRule(min: 5.5, max: 152.2),
                WeightedDenialGroupRequiredCodeRule(message: "weighted denial group needs a value"),
                WeightedDenialGroupRequiredFacilityRule(message: "weighted denial group needs a value"),
            ]
        )
    }
}
