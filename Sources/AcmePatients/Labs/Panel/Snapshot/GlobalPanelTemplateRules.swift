import AcmePlatform
import Foundation

extension Labs {
    /// A rule a global panel template must pass. Check returns its problems, or none.
    protocol GlobalPanelTemplateRule {
        func check(_ item: GlobalPanelTemplate) -> [String]
    }

    final class GlobalPanelTemplateRequiredChannelRule: GlobalPanelTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPanelTemplate) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalPanelTemplateRequiredLabelRule: GlobalPanelTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalPanelTemplate) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalPanelTemplateGraceDaysRangeRule: GlobalPanelTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPanelTemplate) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalPanelTemplateDiscountRangeRule: GlobalPanelTemplateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPanelTemplate) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalPanelTemplateSequenceRangeRule: GlobalPanelTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalPanelTemplate) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalPanelTemplateChannelLengthRule: GlobalPanelTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalPanelTemplate) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global panel template.
    final class GlobalPanelTemplateValidator {
        var rules: [any GlobalPanelTemplateRule]

        init(rules: [any GlobalPanelTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalPanelTemplate) -> [String] {
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

        func requireValid(_ item: GlobalPanelTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalPanelTemplate]) -> [String: [String]] {
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

    static func defaultGlobalPanelTemplateValidator() -> GlobalPanelTemplateValidator {
        return GlobalPanelTemplateValidator(
            rules: [
                GlobalPanelTemplateRequiredChannelRule(message: "global panel template needs this field"),
                GlobalPanelTemplateRequiredLabelRule(message: "global panel template needs a value"),
                GlobalPanelTemplateGraceDaysRangeRule(min: 32, max: 1000),
                GlobalPanelTemplateDiscountRangeRule(min: 1.4, max: 1548.0),
                GlobalPanelTemplateSequenceRangeRule(min: 1000, max: 86400),
                GlobalPanelTemplateChannelLengthRule(maxLength: 3600),
            ]
        )
    }
}
