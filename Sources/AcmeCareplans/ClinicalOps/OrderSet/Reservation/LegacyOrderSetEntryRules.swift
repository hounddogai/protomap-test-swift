import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy order set entry must pass. Check returns its problems, or none.
    protocol LegacyOrderSetEntryRule {
        func check(_ item: LegacyOrderSetEntry) -> [String]
    }

    final class LegacyOrderSetEntryPhoneLengthRule: LegacyOrderSetEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetEntry) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOrderSetEntryLabelLengthRule: LegacyOrderSetEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyOrderSetEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyOrderSetEntryRefillsRangeRule: LegacyOrderSetEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyOrderSetEntry) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyOrderSetEntryCodePrefixRule: LegacyOrderSetEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyOrderSetEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyOrderSetEntryRequiredCodeRule: LegacyOrderSetEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyOrderSetEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy order set entry.
    final class LegacyOrderSetEntryValidator {
        var rules: [any LegacyOrderSetEntryRule]

        init(rules: [any LegacyOrderSetEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyOrderSetEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyOrderSetEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyOrderSetEntry]) -> [String: [String]] {
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

    static func defaultLegacyOrderSetEntryValidator() -> LegacyOrderSetEntryValidator {
        return LegacyOrderSetEntryValidator(
            rules: [
                LegacyOrderSetEntryPhoneLengthRule(maxLength: 1000),
                LegacyOrderSetEntryLabelLengthRule(maxLength: 86400),
                LegacyOrderSetEntryRefillsRangeRule(min: 1000, max: 3600),
                LegacyOrderSetEntryCodePrefixRule(prefix: "Q"),
                LegacyOrderSetEntryRequiredCodeRule(message: "legacy order set entry needs a value"),
            ]
        )
    }
}
