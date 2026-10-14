import AcmePlatform
import Foundation

extension Labs {
    /// A rule a lenient reference range schedule must pass. Check returns its problems, or none.
    protocol LenientReferenceRangeScheduleRule {
        func check(_ item: LenientReferenceRangeSchedule) -> [String]
    }

    final class LenientReferenceRangeScheduleCodePrefixRule: LenientReferenceRangeScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientReferenceRangeSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientReferenceRangeScheduleRequiredCodeRule: LenientReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientReferenceRangeScheduleRequiredLocaleRule: LenientReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientReferenceRangeSchedule) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient reference range schedule.
    final class LenientReferenceRangeScheduleValidator {
        var rules: [any LenientReferenceRangeScheduleRule]

        init(rules: [any LenientReferenceRangeScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientReferenceRangeSchedule) -> [String] {
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

        func requireValid(_ item: LenientReferenceRangeSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientReferenceRangeSchedule]) -> [String: [String]] {
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

    static func defaultLenientReferenceRangeScheduleValidator() -> LenientReferenceRangeScheduleValidator {
        return LenientReferenceRangeScheduleValidator(
            rules: [
                LenientReferenceRangeScheduleCodePrefixRule(prefix: "OPS"),
                LenientReferenceRangeScheduleRequiredCodeRule(
                    message: "lenient reference range schedule needs a value"
                ),
                LenientReferenceRangeScheduleRequiredLocaleRule(
                    message: "lenient reference range schedule needs an entry"
                ),
            ]
        )
    }
}
