import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global network schedule must pass. Check returns its problems, or none.
    protocol GlobalNetworkScheduleRule {
        func check(_ item: GlobalNetworkSchedule) -> [String]
    }

    final class GlobalNetworkScheduleRequiredCodeRule: GlobalNetworkScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalNetworkSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalNetworkScheduleAllowedContactEmailRule: GlobalNetworkScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalNetworkSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is missing"]
            }
            return []
        }
    }

    final class GlobalNetworkScheduleExternalRefLengthRule: GlobalNetworkScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalNetworkSchedule) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global network schedule.
    final class GlobalNetworkScheduleValidator {
        var rules: [any GlobalNetworkScheduleRule]

        init(rules: [any GlobalNetworkScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalNetworkSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalNetworkSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalNetworkSchedule]) -> [String: [String]] {
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

    static func defaultGlobalNetworkScheduleValidator() -> GlobalNetworkScheduleValidator {
        return GlobalNetworkScheduleValidator(
            rules: [
                GlobalNetworkScheduleRequiredCodeRule(message: "global network schedule needs a value"),
                GlobalNetworkScheduleAllowedContactEmailRule(allowed: ["default"]),
                GlobalNetworkScheduleExternalRefLengthRule(maxLength: 3600),
            ]
        )
    }
}
