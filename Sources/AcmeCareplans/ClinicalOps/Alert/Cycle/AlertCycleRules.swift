import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert cycle must pass. Check returns its problems, or none.
    protocol AlertCycleRule {
        func check(_ item: AlertCycle) -> [String]
    }

    final class AlertCycleRequiredLabelRule: AlertCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertCycleRequiredCategoryRule: AlertCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertCycle) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertCycleCategoryLengthRule: AlertCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertCycle) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertCycleRequiredCodeRule: AlertCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertCycleOwnerIDLengthRule: AlertCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertCycle) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertCycleAmountRangeRule: AlertCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertCycle) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert cycle.
    final class AlertCycleValidator {
        var rules: [any AlertCycleRule]

        init(rules: [any AlertCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertCycle) -> [String] {
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

        func requireValid(_ item: AlertCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertCycle]) -> [String: [String]] {
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

    static func defaultAlertCycleValidator() -> AlertCycleValidator {
        return AlertCycleValidator(
            rules: [
                AlertCycleRequiredLabelRule(message: "alert cycle needs a value"),
                AlertCycleRequiredCategoryRule(message: "alert cycle needs this field"),
                AlertCycleCategoryLengthRule(maxLength: 32),
                AlertCycleRequiredCodeRule(message: "alert cycle needs an entry"),
                AlertCycleOwnerIDLengthRule(maxLength: 86400),
                AlertCycleAmountRangeRule(min: 2.1, max: 4154.7),
            ]
        )
    }
}
