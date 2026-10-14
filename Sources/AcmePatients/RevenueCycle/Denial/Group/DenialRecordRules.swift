import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial record must pass. Check returns its problems, or none.
    protocol DenialRecordRule {
        func check(_ item: DenialRecord) -> [String]
    }

    final class DenialRecordWindowDaysRangeRule: DenialRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialRecord) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialRecordAmountRangeRule: DenialRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialRecord) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DenialRecordRequiredLabelRule: DenialRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialRecordRequiredNameRule: DenialRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial record.
    final class DenialRecordValidator {
        var rules: [any DenialRecordRule]

        init(rules: [any DenialRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialRecord) -> [String] {
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

        func requireValid(_ item: DenialRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialRecord]) -> [String: [String]] {
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

    static func defaultDenialRecordValidator() -> DenialRecordValidator {
        return DenialRecordValidator(
            rules: [
                DenialRecordWindowDaysRangeRule(min: 32, max: 255),
                DenialRecordAmountRangeRule(min: 6.6, max: 4692.3),
                DenialRecordRequiredLabelRule(message: "denial record needs an entry"),
                DenialRecordRequiredNameRule(message: "denial record needs a value"),
            ]
        )
    }
}
