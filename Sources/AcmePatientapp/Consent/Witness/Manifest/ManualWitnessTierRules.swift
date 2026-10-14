import AcmePlatform
import Foundation

extension Consent {
    /// A rule a manual witness tier must pass. Check returns its problems, or none.
    protocol ManualWitnessTierRule {
        func check(_ item: ManualWitnessTier) -> [String]
    }

    final class ManualWitnessTierRequiredCodeRule: ManualWitnessTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualWitnessTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualWitnessTierAllowedSummaryRule: ManualWitnessTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualWitnessTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.summary)) {
                return ["summary \(item.summary) is above maximum"]
            }
            return []
        }
    }

    final class ManualWitnessTierRequiredTitleRule: ManualWitnessTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualWitnessTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual witness tier.
    final class ManualWitnessTierValidator {
        var rules: [any ManualWitnessTierRule]

        init(rules: [any ManualWitnessTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualWitnessTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualWitnessTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualWitnessTier]) -> [String: [String]] {
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

    static func defaultManualWitnessTierValidator() -> ManualWitnessTierValidator {
        return ManualWitnessTierValidator(
            rules: [
                ManualWitnessTierRequiredCodeRule(message: "manual witness tier needs a value"),
                ManualWitnessTierAllowedSummaryRule(allowed: []),
                ManualWitnessTierRequiredTitleRule(message: "manual witness tier needs an entry"),
            ]
        )
    }
}
