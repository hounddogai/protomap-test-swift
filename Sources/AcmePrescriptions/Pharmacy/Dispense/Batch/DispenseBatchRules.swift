import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense batch must pass. Check returns its problems, or none.
    protocol DispenseBatchRule {
        func check(_ item: DispenseBatch) -> [String]
    }

    final class DispenseBatchAcuityRangeRule: DispenseBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseBatch) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseBatchBudgetRangeRule: DispenseBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseBatch) -> [String] {
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

    final class DispenseBatchCodePrefixRule: DispenseBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DispenseBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DispenseBatchRequiredTitleRule: DispenseBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseBatch) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseBatchTitleLengthRule: DispenseBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseBatch) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseBatchClinicianIDLengthRule: DispenseBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseBatch) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense batch.
    final class DispenseBatchValidator {
        var rules: [any DispenseBatchRule]

        init(rules: [any DispenseBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DispenseBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseBatch]) -> [String: [String]] {
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

    static func defaultDispenseBatchValidator() -> DispenseBatchValidator {
        return DispenseBatchValidator(
            rules: [
                DispenseBatchAcuityRangeRule(min: 3600, max: 86400),
                DispenseBatchBudgetRangeRule(min: 7.9, max: 1310.9),
                DispenseBatchCodePrefixRule(prefix: "REF"),
                DispenseBatchRequiredTitleRule(message: "dispense batch needs an entry"),
                DispenseBatchTitleLengthRule(maxLength: 16),
                DispenseBatchClinicianIDLengthRule(maxLength: 3600),
            ]
        )
    }
}
