import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy preference must pass. Check returns its problems, or none.
    protocol ProxyPreferenceRule {
        func check(_ item: ProxyPreference) -> [String]
    }

    final class ProxyPreferenceTagsLimitRule: ProxyPreferenceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: ProxyPreference) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class ProxyPreferenceCeilingRangeRule: ProxyPreferenceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyPreference) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyPreferenceRequiredCodeRule: ProxyPreferenceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyPreference) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy preference.
    final class ProxyPreferenceValidator {
        var rules: [any ProxyPreferenceRule]

        init(rules: [any ProxyPreferenceRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyPreference) -> [String] {
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

        func requireValid(_ item: ProxyPreference) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyPreference]) -> [String: [String]] {
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

    static func defaultProxyPreferenceValidator() -> ProxyPreferenceValidator {
        return ProxyPreferenceValidator(
            rules: [
                ProxyPreferenceTagsLimitRule(maxCount: 64, banned: ["manual"]),
                ProxyPreferenceCeilingRangeRule(min: 0.8, max: 2008.4),
                ProxyPreferenceRequiredCodeRule(message: "proxy preference needs this field"),
            ]
        )
    }
}
