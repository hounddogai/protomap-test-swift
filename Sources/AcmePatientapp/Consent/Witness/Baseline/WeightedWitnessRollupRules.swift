import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted witness rollup must pass. Check returns its problems, or none.
    protocol WeightedWitnessRollupRule {
        func check(_ item: WeightedWitnessRollup) -> [String]
    }

    final class WeightedWitnessRollupAllowedExternalRefRule: WeightedWitnessRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedWitnessRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is stale"]
            }
            return []
        }
    }

    final class WeightedWitnessRollupEndsAtRangeRule: WeightedWitnessRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedWitnessRollup) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedWitnessRollupRequiredFacilityRule: WeightedWitnessRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedWitnessRollup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedWitnessRollupCodeLengthRule: WeightedWitnessRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedWitnessRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedWitnessRollupCodePrefixRule: WeightedWitnessRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedWitnessRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted witness rollup.
    final class WeightedWitnessRollupValidator {
        var rules: [any WeightedWitnessRollupRule]

        init(rules: [any WeightedWitnessRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedWitnessRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedWitnessRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedWitnessRollup]) -> [String: [String]] {
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

    static func defaultWeightedWitnessRollupValidator() -> WeightedWitnessRollupValidator {
        return WeightedWitnessRollupValidator(
            rules: [
                WeightedWitnessRollupAllowedExternalRefRule(allowed: []),
                WeightedWitnessRollupEndsAtRangeRule(min: 80, max: 3600),
                WeightedWitnessRollupRequiredFacilityRule(message: "weighted witness rollup needs a value"),
                WeightedWitnessRollupCodeLengthRule(maxLength: 1000),
                WeightedWitnessRollupCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
