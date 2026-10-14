import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation record must pass. Check returns its problems, or none.
    protocol IsolationRecordRule {
        func check(_ item: IsolationRecord) -> [String]
    }

    final class IsolationRecordRequiredLabelRule: IsolationRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationRecordRequiredCodeRule: IsolationRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationRecordCodeLengthRule: IsolationRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class IsolationRecordWeightRangeRule: IsolationRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: IsolationRecord) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a isolation record.
    final class IsolationRecordValidator {
        var rules: [any IsolationRecordRule]

        init(rules: [any IsolationRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationRecord) -> [String] {
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

        func requireValid(_ item: IsolationRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationRecord]) -> [String: [String]] {
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

    static func defaultIsolationRecordValidator() -> IsolationRecordValidator {
        return IsolationRecordValidator(
            rules: [
                IsolationRecordRequiredLabelRule(message: "isolation record needs a value"),
                IsolationRecordRequiredCodeRule(message: "isolation record needs this field"),
                IsolationRecordCodeLengthRule(maxLength: 3600),
                IsolationRecordWeightRangeRule(min: 2.8, max: 2245.8),
            ]
        )
    }
}
