import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional order set group must pass. Check returns its problems, or none.
    protocol RegionalOrderSetGroupRule {
        func check(_ item: RegionalOrderSetGroup) -> [String]
    }

    final class RegionalOrderSetGroupRequiredNameRule: RegionalOrderSetGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalOrderSetGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalOrderSetGroupCodePrefixRule: RegionalOrderSetGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalOrderSetGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalOrderSetGroupCodeLengthRule: RegionalOrderSetGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalOrderSetGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional order set group.
    final class RegionalOrderSetGroupValidator {
        var rules: [any RegionalOrderSetGroupRule]

        init(rules: [any RegionalOrderSetGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalOrderSetGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalOrderSetGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalOrderSetGroup]) -> [String: [String]] {
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

    static func defaultRegionalOrderSetGroupValidator() -> RegionalOrderSetGroupValidator {
        return RegionalOrderSetGroupValidator(
            rules: [
                RegionalOrderSetGroupRequiredNameRule(message: "regional order set group needs this field"),
                RegionalOrderSetGroupCodePrefixRule(prefix: "OPS"),
                RegionalOrderSetGroupCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
