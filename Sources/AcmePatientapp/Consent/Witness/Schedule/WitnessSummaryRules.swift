import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness summary must pass. Check returns its problems, or none.
    protocol WitnessSummaryRule {
        func check(_ item: WitnessSummary) -> [String]
    }

    final class WitnessSummaryRequiredLabelRule: WitnessSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessSummaryRequiredCodeRule: WitnessSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessSummaryVisibleGuardRule: WitnessSummaryRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WitnessSummary) -> [String] {
            if item.visible && (item.cost > limit) {
                return ["cost \(item.cost) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a witness summary.
    final class WitnessSummaryValidator {
        var rules: [any WitnessSummaryRule]

        init(rules: [any WitnessSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessSummary) -> [String] {
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

        func requireValid(_ item: WitnessSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessSummary]) -> [String: [String]] {
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

    static func defaultWitnessSummaryValidator() -> WitnessSummaryValidator {
        return WitnessSummaryValidator(
            rules: [
                WitnessSummaryRequiredLabelRule(message: "witness summary needs this field"),
                WitnessSummaryRequiredCodeRule(message: "witness summary needs an entry"),
                WitnessSummaryVisibleGuardRule(limit: 1.8),
            ]
        )
    }
}
