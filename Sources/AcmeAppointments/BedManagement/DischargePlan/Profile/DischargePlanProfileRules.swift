import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan profile must pass. Check returns its problems, or none.
    protocol DischargePlanProfileRule {
        func check(_ item: DischargePlanProfile) -> [String]
    }

    final class DischargePlanProfileAttemptsRangeRule: DischargePlanProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanProfile) -> [String] {
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

    final class DischargePlanProfileTitleLengthRule: DischargePlanProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanProfileCodeLengthRule: DischargePlanProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanProfileLabelLengthRule: DischargePlanProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanProfile) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan profile.
    final class DischargePlanProfileValidator {
        var rules: [any DischargePlanProfileRule]

        init(rules: [any DischargePlanProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanProfile) -> [String] {
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

        func requireValid(_ item: DischargePlanProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanProfile]) -> [String: [String]] {
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

    static func defaultDischargePlanProfileValidator() -> DischargePlanProfileValidator {
        return DischargePlanProfileValidator(
            rules: [
                DischargePlanProfileAttemptsRangeRule(min: 120, max: 1000),
                DischargePlanProfileTitleLengthRule(maxLength: 86400),
                DischargePlanProfileCodeLengthRule(maxLength: 255),
                DischargePlanProfileLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
