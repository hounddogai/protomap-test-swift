import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual discharge plan target must pass. Check returns its problems, or none.
    protocol ManualDischargePlanTargetRule {
        func check(_ item: ManualDischargePlanTarget) -> [String]
    }

    final class ManualDischargePlanTargetRequiredLabelRule: ManualDischargePlanTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanTarget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDischargePlanTargetLabelLengthRule: ManualDischargePlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDischargePlanTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualDischargePlanTargetAttemptsRangeRule: ManualDischargePlanTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualDischargePlanTarget) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualDischargePlanTargetRequiredCodeRule: ManualDischargePlanTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDischargePlanTargetRequiredCountryRule: ManualDischargePlanTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualDischargePlanTarget) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualDischargePlanTargetCountryLengthRule: ManualDischargePlanTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualDischargePlanTarget) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual discharge plan target.
    final class ManualDischargePlanTargetValidator {
        var rules: [any ManualDischargePlanTargetRule]

        init(rules: [any ManualDischargePlanTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualDischargePlanTarget) -> [String] {
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

        func requireValid(_ item: ManualDischargePlanTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualDischargePlanTarget]) -> [String: [String]] {
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

    static func defaultManualDischargePlanTargetValidator() -> ManualDischargePlanTargetValidator {
        return ManualDischargePlanTargetValidator(
            rules: [
                ManualDischargePlanTargetRequiredLabelRule(message: "manual discharge plan target needs this field"),
                ManualDischargePlanTargetLabelLengthRule(maxLength: 120),
                ManualDischargePlanTargetAttemptsRangeRule(min: 16, max: 64),
                ManualDischargePlanTargetRequiredCodeRule(message: "manual discharge plan target needs this field"),
                ManualDischargePlanTargetRequiredCountryRule(message: "manual discharge plan target needs a value"),
                ManualDischargePlanTargetCountryLengthRule(maxLength: 255),
            ]
        )
    }
}
