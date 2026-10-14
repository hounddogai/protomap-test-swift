import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy rule must pass. Check returns its problems, or none.
    protocol ProxyRuleRule {
        func check(_ item: ProxyRule) -> [String]
    }

    final class ProxyRuleRequiredCodeRule: ProxyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyRuleDiagnosisCodeLengthRule: ProxyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyRule) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyRuleDurationMinutesRangeRule: ProxyRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyRule) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProxyRuleRequiredFacilityRule: ProxyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyRule) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyRuleRequiredTitleRule: ProxyRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyRuleCodeLengthRule: ProxyRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy rule.
    final class ProxyRuleValidator {
        var rules: [any ProxyRuleRule]

        init(rules: [any ProxyRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyRule) -> [String] {
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

        func requireValid(_ item: ProxyRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyRule]) -> [String: [String]] {
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

    static func defaultProxyRuleValidator() -> ProxyRuleValidator {
        return ProxyRuleValidator(
            rules: [
                ProxyRuleRequiredCodeRule(message: "proxy rule needs a value"),
                ProxyRuleDiagnosisCodeLengthRule(maxLength: 120),
                ProxyRuleDurationMinutesRangeRule(min: 255, max: 1000),
                ProxyRuleRequiredFacilityRule(message: "proxy rule needs an entry"),
                ProxyRuleRequiredTitleRule(message: "proxy rule needs an entry"),
                ProxyRuleCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
