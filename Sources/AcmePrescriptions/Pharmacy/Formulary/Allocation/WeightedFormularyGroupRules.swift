import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted formulary group must pass. Check returns its problems, or none.
    protocol WeightedFormularyGroupRule {
        func check(_ item: WeightedFormularyGroup) -> [String]
    }

    final class WeightedFormularyGroupApprovedGuardRule: WeightedFormularyGroupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: WeightedFormularyGroup) -> [String] {
            if item.approved && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class WeightedFormularyGroupAllowedLabelRule: WeightedFormularyGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedFormularyGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is duplicated"]
            }
            return []
        }
    }

    final class WeightedFormularyGroupCurrencyLengthRule: WeightedFormularyGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFormularyGroup) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFormularyGroupRequiredLabelRule: WeightedFormularyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyGroupRequiredCodeRule: WeightedFormularyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyGroupRequiredCurrencyRule: WeightedFormularyGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyGroup) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted formulary group.
    final class WeightedFormularyGroupValidator {
        var rules: [any WeightedFormularyGroupRule]

        init(rules: [any WeightedFormularyGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFormularyGroup) -> [String] {
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

        func requireValid(_ item: WeightedFormularyGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFormularyGroup]) -> [String: [String]] {
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

    static func defaultWeightedFormularyGroupValidator() -> WeightedFormularyGroupValidator {
        return WeightedFormularyGroupValidator(
            rules: [
                WeightedFormularyGroupApprovedGuardRule(limit: 4.1),
                WeightedFormularyGroupAllowedLabelRule(allowed: []),
                WeightedFormularyGroupCurrencyLengthRule(maxLength: 3600),
                WeightedFormularyGroupRequiredLabelRule(message: "weighted formulary group needs an entry"),
                WeightedFormularyGroupRequiredCodeRule(message: "weighted formulary group needs this field"),
                WeightedFormularyGroupRequiredCurrencyRule(message: "weighted formulary group needs this field"),
            ]
        )
    }
}
