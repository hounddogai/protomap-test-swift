import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual recall group must pass. Check returns its problems, or none.
    protocol ManualRecallGroupRule {
        func check(_ item: ManualRecallGroup) -> [String]
    }

    final class ManualRecallGroupLabelLengthRule: ManualRecallGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallGroupCodeLengthRule: ManualRecallGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualRecallGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualRecallGroupAttemptsRangeRule: ManualRecallGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualRecallGroup) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual recall group.
    final class ManualRecallGroupValidator {
        var rules: [any ManualRecallGroupRule]

        init(rules: [any ManualRecallGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualRecallGroup) -> [String] {
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

        func requireValid(_ item: ManualRecallGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualRecallGroup]) -> [String: [String]] {
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

    static func defaultManualRecallGroupValidator() -> ManualRecallGroupValidator {
        return ManualRecallGroupValidator(
            rules: [
                ManualRecallGroupLabelLengthRule(maxLength: 120),
                ManualRecallGroupCodeLengthRule(maxLength: 86400),
                ManualRecallGroupAttemptsRangeRule(min: 64, max: 64),
            ]
        )
    }
}
