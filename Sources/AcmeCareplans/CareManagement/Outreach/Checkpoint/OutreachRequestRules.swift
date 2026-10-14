import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach request must pass. Check returns its problems, or none.
    protocol OutreachRequestRule {
        func check(_ item: OutreachRequest) -> [String]
    }

    final class OutreachRequestRequiredCodeRule: OutreachRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachRequestAllowedCurrencyRule: OutreachRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.currency)) {
                return ["currency \(item.currency) is above maximum"]
            }
            return []
        }
    }

    final class OutreachRequestRequiredChecksumRule: OutreachRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachRequest) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach request.
    final class OutreachRequestValidator {
        var rules: [any OutreachRequestRule]

        init(rules: [any OutreachRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachRequest]) -> [String: [String]] {
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

    static func defaultOutreachRequestValidator() -> OutreachRequestValidator {
        return OutreachRequestValidator(
            rules: [
                OutreachRequestRequiredCodeRule(message: "outreach request needs an entry"),
                OutreachRequestAllowedCurrencyRule(allowed: ["regional"]),
                OutreachRequestRequiredChecksumRule(message: "outreach request needs a value"),
            ]
        )
    }
}
