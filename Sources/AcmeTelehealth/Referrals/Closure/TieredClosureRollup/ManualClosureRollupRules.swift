import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual closure rollup must pass. Check returns its problems, or none.
    protocol ManualClosureRollupRule {
        func check(_ item: ManualClosureRollup) -> [String]
    }

    final class ManualClosureRollupAllowedBedRule: ManualClosureRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualClosureRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.bed)) {
                return ["bed \(item.bed) is too long"]
            }
            return []
        }
    }

    final class ManualClosureRollupRequiredBedRule: ManualClosureRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualClosureRollup) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualClosureRollupVisitMinutesRangeRule: ManualClosureRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualClosureRollup) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualClosureRollupCodeLengthRule: ManualClosureRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureRollupTitleLengthRule: ManualClosureRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualClosureRollupBedLengthRule: ManualClosureRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualClosureRollup) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual closure rollup.
    final class ManualClosureRollupValidator {
        var rules: [any ManualClosureRollupRule]

        init(rules: [any ManualClosureRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualClosureRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualClosureRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualClosureRollup]) -> [String: [String]] {
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

    static func defaultManualClosureRollupValidator() -> ManualClosureRollupValidator {
        return ManualClosureRollupValidator(
            rules: [
                ManualClosureRollupAllowedBedRule(allowed: ["rolling", "pending", "global"]),
                ManualClosureRollupRequiredBedRule(message: "manual closure rollup needs a value"),
                ManualClosureRollupVisitMinutesRangeRule(min: 3600, max: 86400),
                ManualClosureRollupCodeLengthRule(maxLength: 3600),
                ManualClosureRollupTitleLengthRule(maxLength: 1000),
                ManualClosureRollupBedLengthRule(maxLength: 3600),
            ]
        )
    }
}
