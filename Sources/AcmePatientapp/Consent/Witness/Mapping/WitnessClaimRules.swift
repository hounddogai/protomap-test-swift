import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness claim must pass. Check returns its problems, or none.
    protocol WitnessClaimRule {
        func check(_ item: WitnessClaim) -> [String]
    }

    final class WitnessClaimLabelLengthRule: WitnessClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessClaimCostRangeRule: WitnessClaimRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessClaim) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WitnessClaimRequiredCodeRule: WitnessClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessClaimCodePrefixRule: WitnessClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness claim.
    final class WitnessClaimValidator {
        var rules: [any WitnessClaimRule]

        init(rules: [any WitnessClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessClaim]) -> [String: [String]] {
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

    static func defaultWitnessClaimValidator() -> WitnessClaimValidator {
        return WitnessClaimValidator(
            rules: [
                WitnessClaimLabelLengthRule(maxLength: 1000),
                WitnessClaimCostRangeRule(min: 3.5, max: 2526.5),
                WitnessClaimRequiredCodeRule(message: "witness claim needs this field"),
                WitnessClaimCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
