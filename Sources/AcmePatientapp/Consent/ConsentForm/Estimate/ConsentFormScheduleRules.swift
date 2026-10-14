import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form schedule must pass. Check returns its problems, or none.
    protocol ConsentFormScheduleRule {
        func check(_ item: ConsentFormSchedule) -> [String]
    }

    final class ConsentFormScheduleTitleLengthRule: ConsentFormScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormScheduleLocaleLengthRule: ConsentFormScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormSchedule) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormScheduleCodePrefixRule: ConsentFormScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormScheduleRequiredCodeRule: ConsentFormScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormScheduleDosageMgRangeRule: ConsentFormScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormSchedule) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormScheduleRequiredTitleRule: ConsentFormScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form schedule.
    final class ConsentFormScheduleValidator {
        var rules: [any ConsentFormScheduleRule]

        init(rules: [any ConsentFormScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormSchedule]) -> [String: [String]] {
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

    static func defaultConsentFormScheduleValidator() -> ConsentFormScheduleValidator {
        return ConsentFormScheduleValidator(
            rules: [
                ConsentFormScheduleTitleLengthRule(maxLength: 1000),
                ConsentFormScheduleLocaleLengthRule(maxLength: 3600),
                ConsentFormScheduleCodePrefixRule(prefix: "OPS"),
                ConsentFormScheduleRequiredCodeRule(message: "consent form schedule needs this field"),
                ConsentFormScheduleDosageMgRangeRule(min: 9.5, max: 4604.3),
                ConsentFormScheduleRequiredTitleRule(message: "consent form schedule needs an entry"),
            ]
        )
    }
}
