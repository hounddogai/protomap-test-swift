import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession schedule must pass. Check returns its problems, or none.
    protocol AccessionScheduleRule {
        func check(_ item: AccessionSchedule) -> [String]
    }

    final class AccessionScheduleRevisionRangeRule: AccessionScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionSchedule) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AccessionScheduleRequiredCountryRule: AccessionScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionSchedule) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionScheduleCountryLengthRule: AccessionScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionSchedule) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionScheduleRatioRangeRule: AccessionScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionSchedule) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AccessionScheduleCodePrefixRule: AccessionScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionScheduleDescriptionLengthRule: AccessionScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionSchedule) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession schedule.
    final class AccessionScheduleValidator {
        var rules: [any AccessionScheduleRule]

        init(rules: [any AccessionScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AccessionSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionSchedule]) -> [String: [String]] {
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

    static func defaultAccessionScheduleValidator() -> AccessionScheduleValidator {
        return AccessionScheduleValidator(
            rules: [
                AccessionScheduleRevisionRangeRule(min: 64, max: 255),
                AccessionScheduleRequiredCountryRule(message: "accession schedule needs a value"),
                AccessionScheduleCountryLengthRule(maxLength: 64),
                AccessionScheduleRatioRangeRule(min: 1.5, max: 654.0),
                AccessionScheduleCodePrefixRule(prefix: "ACM"),
                AccessionScheduleDescriptionLengthRule(maxLength: 3600),
            ]
        )
    }
}
