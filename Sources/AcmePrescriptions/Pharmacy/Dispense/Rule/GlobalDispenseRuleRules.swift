import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a global dispense rule must pass. Check returns its problems, or none.
    protocol GlobalDispenseRuleRule {
        func check(_ item: GlobalDispenseRule) -> [String]
    }

    final class GlobalDispenseRuleRequiredCodeRule: GlobalDispenseRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDispenseRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDispenseRuleAllowedLabelRule: GlobalDispenseRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalDispenseRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is not allowed"]
            }
            return []
        }
    }

    final class GlobalDispenseRuleRequiredDiagnosisCodeRule: GlobalDispenseRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDispenseRule) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDispenseRuleActiveGuardRule: GlobalDispenseRuleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: GlobalDispenseRule) -> [String] {
            if item.active && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class GlobalDispenseRuleRequiredRegionRule: GlobalDispenseRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDispenseRule) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global dispense rule.
    final class GlobalDispenseRuleValidator {
        var rules: [any GlobalDispenseRuleRule]

        init(rules: [any GlobalDispenseRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDispenseRule) -> [String] {
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

        func requireValid(_ item: GlobalDispenseRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDispenseRule]) -> [String: [String]] {
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

    static func defaultGlobalDispenseRuleValidator() -> GlobalDispenseRuleValidator {
        return GlobalDispenseRuleValidator(
            rules: [
                GlobalDispenseRuleRequiredCodeRule(message: "global dispense rule needs a value"),
                GlobalDispenseRuleAllowedLabelRule(allowed: []),
                GlobalDispenseRuleRequiredDiagnosisCodeRule(message: "global dispense rule needs an entry"),
                GlobalDispenseRuleActiveGuardRule(limit: 64),
                GlobalDispenseRuleRequiredRegionRule(message: "global dispense rule needs an entry"),
            ]
        )
    }
}
