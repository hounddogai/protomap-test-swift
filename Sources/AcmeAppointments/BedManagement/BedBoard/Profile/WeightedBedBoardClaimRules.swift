import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a weighted bed board claim must pass. Check returns its problems, or none.
    protocol WeightedBedBoardClaimRule {
        func check(_ item: WeightedBedBoardClaim) -> [String]
    }

    final class WeightedBedBoardClaimLabelLengthRule: WeightedBedBoardClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedBedBoardClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedBedBoardClaimNameLengthRule: WeightedBedBoardClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedBedBoardClaim) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedBedBoardClaimRequiredCategoryRule: WeightedBedBoardClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedBedBoardClaim) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedBedBoardClaimCodePrefixRule: WeightedBedBoardClaimRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedBedBoardClaim) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedBedBoardClaimAttemptsRangeRule: WeightedBedBoardClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedBedBoardClaim) -> [String] {
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

    final class WeightedBedBoardClaimAllowedPayerRule: WeightedBedBoardClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedBedBoardClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted bed board claim.
    final class WeightedBedBoardClaimValidator {
        var rules: [any WeightedBedBoardClaimRule]

        init(rules: [any WeightedBedBoardClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedBedBoardClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedBedBoardClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedBedBoardClaim]) -> [String: [String]] {
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

    static func defaultWeightedBedBoardClaimValidator() -> WeightedBedBoardClaimValidator {
        return WeightedBedBoardClaimValidator(
            rules: [
                WeightedBedBoardClaimLabelLengthRule(maxLength: 64),
                WeightedBedBoardClaimNameLengthRule(maxLength: 80),
                WeightedBedBoardClaimRequiredCategoryRule(message: "weighted bed board claim needs a value"),
                WeightedBedBoardClaimCodePrefixRule(prefix: "X"),
                WeightedBedBoardClaimAttemptsRangeRule(min: 80, max: 1000),
                WeightedBedBoardClaimAllowedPayerRule(allowed: []),
            ]
        )
    }
}
