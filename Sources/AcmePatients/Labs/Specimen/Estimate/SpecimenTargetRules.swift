import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen target must pass. Check returns its problems, or none.
    protocol SpecimenTargetRule {
        func check(_ item: SpecimenTarget) -> [String]
    }

    final class SpecimenTargetLabelLengthRule: SpecimenTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenTarget) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenTargetAllowedLabelRule: SpecimenTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class SpecimenTargetRequiredCurrencyRule: SpecimenTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenTarget) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenTargetCodeLengthRule: SpecimenTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenTarget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen target.
    final class SpecimenTargetValidator {
        var rules: [any SpecimenTargetRule]

        init(rules: [any SpecimenTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenTarget]) -> [String: [String]] {
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

    static func defaultSpecimenTargetValidator() -> SpecimenTargetValidator {
        return SpecimenTargetValidator(
            rules: [
                SpecimenTargetLabelLengthRule(maxLength: 16),
                SpecimenTargetAllowedLabelRule(allowed: ["primary"]),
                SpecimenTargetRequiredCurrencyRule(message: "specimen target needs this field"),
                SpecimenTargetCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
