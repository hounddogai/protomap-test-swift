import AcmePlatform
import Foundation

extension Labs {
    /// A rule a tiered panel schedule must pass. Check returns its problems, or none.
    protocol TieredPanelScheduleRule {
        func check(_ item: TieredPanelSchedule) -> [String]
    }

    final class TieredPanelScheduleLabelLengthRule: TieredPanelScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPanelSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPanelScheduleCodePrefixRule: TieredPanelScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredPanelSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredPanelScheduleRequiredPayerRule: TieredPanelScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPanelSchedule) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPanelScheduleMarginRangeRule: TieredPanelScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPanelSchedule) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered panel schedule.
    final class TieredPanelScheduleValidator {
        var rules: [any TieredPanelScheduleRule]

        init(rules: [any TieredPanelScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPanelSchedule) -> [String] {
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

        func requireValid(_ item: TieredPanelSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPanelSchedule]) -> [String: [String]] {
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

    static func defaultTieredPanelScheduleValidator() -> TieredPanelScheduleValidator {
        return TieredPanelScheduleValidator(
            rules: [
                TieredPanelScheduleLabelLengthRule(maxLength: 80),
                TieredPanelScheduleCodePrefixRule(prefix: "Q"),
                TieredPanelScheduleRequiredPayerRule(message: "tiered panel schedule needs an entry"),
                TieredPanelScheduleMarginRangeRule(min: 7.0, max: 2063.2),
            ]
        )
    }
}
