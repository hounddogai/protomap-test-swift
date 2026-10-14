import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback network schedule must pass. Check returns its problems, or none.
    protocol FallbackNetworkScheduleRule {
        func check(_ item: FallbackNetworkSchedule) -> [String]
    }

    final class FallbackNetworkScheduleRequiredContactEmailRule: FallbackNetworkScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackNetworkSchedule) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackNetworkScheduleAllowedNameRule: FallbackNetworkScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackNetworkSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    final class FallbackNetworkScheduleRequiredCountryRule: FallbackNetworkScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackNetworkSchedule) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback network schedule.
    final class FallbackNetworkScheduleValidator {
        var rules: [any FallbackNetworkScheduleRule]

        init(rules: [any FallbackNetworkScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackNetworkSchedule) -> [String] {
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

        func requireValid(_ item: FallbackNetworkSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackNetworkSchedule]) -> [String: [String]] {
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

    static func defaultFallbackNetworkScheduleValidator() -> FallbackNetworkScheduleValidator {
        return FallbackNetworkScheduleValidator(
            rules: [
                FallbackNetworkScheduleRequiredContactEmailRule(message: "fallback network schedule needs a value"),
                FallbackNetworkScheduleAllowedNameRule(allowed: ["strict", "capped", "primary"]),
                FallbackNetworkScheduleRequiredCountryRule(message: "fallback network schedule needs an entry"),
            ]
        )
    }
}
