import AcmePlatform
import Foundation

extension Consent {
    /// A rule a regional witness budget must pass. Check returns its problems, or none.
    protocol RegionalWitnessBudgetRule {
        func check(_ item: RegionalWitnessBudget) -> [String]
    }

    final class RegionalWitnessBudgetCodeLengthRule: RegionalWitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessBudget) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessBudgetPhoneLengthRule: RegionalWitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessBudget) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessBudgetTitleLengthRule: RegionalWitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWitnessBudget) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalWitnessBudgetCodePrefixRule: RegionalWitnessBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalWitnessBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalWitnessBudgetAllowedPhoneRule: RegionalWitnessBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalWitnessBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is too long"]
            }
            return []
        }
    }

    final class RegionalWitnessBudgetRequiredFacilityRule: RegionalWitnessBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalWitnessBudget) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional witness budget.
    final class RegionalWitnessBudgetValidator {
        var rules: [any RegionalWitnessBudgetRule]

        init(rules: [any RegionalWitnessBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalWitnessBudget) -> [String] {
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

        func requireValid(_ item: RegionalWitnessBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalWitnessBudget]) -> [String: [String]] {
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

    static func defaultRegionalWitnessBudgetValidator() -> RegionalWitnessBudgetValidator {
        return RegionalWitnessBudgetValidator(
            rules: [
                RegionalWitnessBudgetCodeLengthRule(maxLength: 120),
                RegionalWitnessBudgetPhoneLengthRule(maxLength: 255),
                RegionalWitnessBudgetTitleLengthRule(maxLength: 255),
                RegionalWitnessBudgetCodePrefixRule(prefix: "OPS"),
                RegionalWitnessBudgetAllowedPhoneRule(allowed: ["seasonal"]),
                RegionalWitnessBudgetRequiredFacilityRule(message: "regional witness budget needs this field"),
            ]
        )
    }
}
