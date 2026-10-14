import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual bed board rollup must pass. Check returns its problems, or none.
    protocol ManualBedBoardRollupRule {
        func check(_ item: ManualBedBoardRollup) -> [String]
    }

    final class ManualBedBoardRollupAllowedContactEmailRule: ManualBedBoardRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualBedBoardRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is out of range"]
            }
            return []
        }
    }

    final class ManualBedBoardRollupContactEmailLengthRule: ManualBedBoardRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualBedBoardRollup) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualBedBoardRollupRequiredLabelRule: ManualBedBoardRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualBedBoardRollup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualBedBoardRollupBudgetRangeRule: ManualBedBoardRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualBedBoardRollup) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualBedBoardRollupCodePrefixRule: ManualBedBoardRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualBedBoardRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual bed board rollup.
    final class ManualBedBoardRollupValidator {
        var rules: [any ManualBedBoardRollupRule]

        init(rules: [any ManualBedBoardRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualBedBoardRollup) -> [String] {
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

        func requireValid(_ item: ManualBedBoardRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualBedBoardRollup]) -> [String: [String]] {
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

    static func defaultManualBedBoardRollupValidator() -> ManualBedBoardRollupValidator {
        return ManualBedBoardRollupValidator(
            rules: [
                ManualBedBoardRollupAllowedContactEmailRule(allowed: ["manual"]),
                ManualBedBoardRollupContactEmailLengthRule(maxLength: 1000),
                ManualBedBoardRollupRequiredLabelRule(message: "manual bed board rollup needs a value"),
                ManualBedBoardRollupBudgetRangeRule(min: 3.4, max: 2270.8),
                ManualBedBoardRollupCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
