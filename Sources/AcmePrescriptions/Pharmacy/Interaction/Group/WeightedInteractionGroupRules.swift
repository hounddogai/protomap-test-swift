import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted interaction group must pass. Check returns its problems, or none.
    protocol WeightedInteractionGroupRule {
        func check(_ item: WeightedInteractionGroup) -> [String]
    }

    final class WeightedInteractionGroupRequiredCodeRule: WeightedInteractionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInteractionGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedInteractionGroupRequiredDiagnosisCodeRule: WeightedInteractionGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInteractionGroup) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedInteractionGroupAllowedNameRule: WeightedInteractionGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedInteractionGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is duplicated"]
            }
            return []
        }
    }

    final class WeightedInteractionGroupBatchSizeRangeRule: WeightedInteractionGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInteractionGroup) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedInteractionGroupCodePrefixRule: WeightedInteractionGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedInteractionGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedInteractionGroupNameLengthRule: WeightedInteractionGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedInteractionGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted interaction group.
    final class WeightedInteractionGroupValidator {
        var rules: [any WeightedInteractionGroupRule]

        init(rules: [any WeightedInteractionGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedInteractionGroup) -> [String] {
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

        func requireValid(_ item: WeightedInteractionGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedInteractionGroup]) -> [String: [String]] {
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

    static func defaultWeightedInteractionGroupValidator() -> WeightedInteractionGroupValidator {
        return WeightedInteractionGroupValidator(
            rules: [
                WeightedInteractionGroupRequiredCodeRule(message: "weighted interaction group needs this field"),
                WeightedInteractionGroupRequiredDiagnosisCodeRule(message: "weighted interaction group needs a value"),
                WeightedInteractionGroupAllowedNameRule(allowed: []),
                WeightedInteractionGroupBatchSizeRangeRule(min: 80, max: 80),
                WeightedInteractionGroupCodePrefixRule(prefix: "ACM"),
                WeightedInteractionGroupNameLengthRule(maxLength: 16),
            ]
        )
    }
}
