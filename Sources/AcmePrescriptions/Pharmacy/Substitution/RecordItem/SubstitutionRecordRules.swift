import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution record must pass. Check returns its problems, or none.
    protocol SubstitutionRecordRule {
        func check(_ item: SubstitutionRecord) -> [String]
    }

    final class SubstitutionRecordRequiredNameRule: SubstitutionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionRecord) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionRecordDiscountRangeRule: SubstitutionRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionRecord) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SubstitutionRecordAllowedCodeRule: SubstitutionRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class SubstitutionRecordNameLengthRule: SubstitutionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionRecordRequiredNotesRule: SubstitutionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionRecord) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionRecordCodePrefixRule: SubstitutionRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution record.
    final class SubstitutionRecordValidator {
        var rules: [any SubstitutionRecordRule]

        init(rules: [any SubstitutionRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionRecord) -> [String] {
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

        func requireValid(_ item: SubstitutionRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionRecord]) -> [String: [String]] {
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

    static func defaultSubstitutionRecordValidator() -> SubstitutionRecordValidator {
        return SubstitutionRecordValidator(
            rules: [
                SubstitutionRecordRequiredNameRule(message: "substitution record needs a value"),
                SubstitutionRecordDiscountRangeRule(min: 4.8, max: 131.3),
                SubstitutionRecordAllowedCodeRule(allowed: ["scheduled", "manual"]),
                SubstitutionRecordNameLengthRule(maxLength: 255),
                SubstitutionRecordRequiredNotesRule(message: "substitution record needs an entry"),
                SubstitutionRecordCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
