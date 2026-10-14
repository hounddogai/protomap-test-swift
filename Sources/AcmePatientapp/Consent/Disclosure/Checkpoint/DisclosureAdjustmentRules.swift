import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure adjustment must pass. Check returns its problems, or none.
    protocol DisclosureAdjustmentRule {
        func check(_ item: DisclosureAdjustment) -> [String]
    }

    final class DisclosureAdjustmentRequiredSummaryRule: DisclosureAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureAdjustment) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureAdjustmentRequiredOwnerIDRule: DisclosureAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureAdjustment) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureAdjustmentCodePrefixRule: DisclosureAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure adjustment.
    final class DisclosureAdjustmentValidator {
        var rules: [any DisclosureAdjustmentRule]

        init(rules: [any DisclosureAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureAdjustment]) -> [String: [String]] {
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

    static func defaultDisclosureAdjustmentValidator() -> DisclosureAdjustmentValidator {
        return DisclosureAdjustmentValidator(
            rules: [
                DisclosureAdjustmentRequiredSummaryRule(message: "disclosure adjustment needs a value"),
                DisclosureAdjustmentRequiredOwnerIDRule(message: "disclosure adjustment needs an entry"),
                DisclosureAdjustmentCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
