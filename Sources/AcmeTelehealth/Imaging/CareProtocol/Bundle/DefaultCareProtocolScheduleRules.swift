import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a default care protocol schedule must pass. Check returns its problems, or none.
    protocol DefaultCareProtocolScheduleRule {
        func check(_ item: DefaultCareProtocolSchedule) -> [String]
    }

    final class DefaultCareProtocolScheduleCodePrefixRule: DefaultCareProtocolScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCareProtocolSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCareProtocolScheduleAllowedCodeRule: DefaultCareProtocolScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCareProtocolSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class DefaultCareProtocolScheduleRequiredCategoryRule: DefaultCareProtocolScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCareProtocolSchedule) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default care protocol schedule.
    final class DefaultCareProtocolScheduleValidator {
        var rules: [any DefaultCareProtocolScheduleRule]

        init(rules: [any DefaultCareProtocolScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCareProtocolSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCareProtocolSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCareProtocolSchedule]) -> [String: [String]] {
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

    static func defaultDefaultCareProtocolScheduleValidator() -> DefaultCareProtocolScheduleValidator {
        return DefaultCareProtocolScheduleValidator(
            rules: [
                DefaultCareProtocolScheduleCodePrefixRule(prefix: "OPS"),
                DefaultCareProtocolScheduleAllowedCodeRule(allowed: ["weighted", "fallback"]),
                DefaultCareProtocolScheduleRequiredCategoryRule(
                    message: "default care protocol schedule needs an entry"
                ),
            ]
        )
    }
}
