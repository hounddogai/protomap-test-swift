import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure policy must pass. Check returns its problems, or none.
    protocol DisclosurePolicyRule {
        func check(_ item: DisclosurePolicy) -> [String]
    }

    final class DisclosurePolicyRequiredProcedureCodeRule: DisclosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosurePolicy) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosurePolicyAllowedProcedureCodeRule: DisclosurePolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosurePolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.procedureCode)) {
                return ["procedure code \(item.procedureCode) is not allowed"]
            }
            return []
        }
    }

    final class DisclosurePolicyRequiredSegmentRule: DisclosurePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosurePolicy) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure policy.
    final class DisclosurePolicyValidator {
        var rules: [any DisclosurePolicyRule]

        init(rules: [any DisclosurePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosurePolicy) -> [String] {
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

        func requireValid(_ item: DisclosurePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosurePolicy]) -> [String: [String]] {
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

    static func defaultDisclosurePolicyValidator() -> DisclosurePolicyValidator {
        return DisclosurePolicyValidator(
            rules: [
                DisclosurePolicyRequiredProcedureCodeRule(message: "disclosure policy needs this field"),
                DisclosurePolicyAllowedProcedureCodeRule(allowed: ["pending", "regional", "default"]),
                DisclosurePolicyRequiredSegmentRule(message: "disclosure policy needs a value"),
            ]
        )
    }
}
