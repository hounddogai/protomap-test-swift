import AcmePlatform
import Foundation

extension Labs {
    /// A rule a accession rollup must pass. Check returns its problems, or none.
    protocol AccessionRollupRule {
        func check(_ item: AccessionRollup) -> [String]
    }

    final class AccessionRollupCodePrefixRule: AccessionRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AccessionRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AccessionRollupNameLengthRule: AccessionRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AccessionRollup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AccessionRollupRequiredCodeRule: AccessionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionRollupRequiredEncounterIDRule: AccessionRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AccessionRollup) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AccessionRollupDiscountRangeRule: AccessionRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AccessionRollup) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a accession rollup.
    final class AccessionRollupValidator {
        var rules: [any AccessionRollupRule]

        init(rules: [any AccessionRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: AccessionRollup) -> [String] {
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

        func requireValid(_ item: AccessionRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AccessionRollup]) -> [String: [String]] {
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

    static func defaultAccessionRollupValidator() -> AccessionRollupValidator {
        return AccessionRollupValidator(
            rules: [
                AccessionRollupCodePrefixRule(prefix: "REF"),
                AccessionRollupNameLengthRule(maxLength: 16),
                AccessionRollupRequiredCodeRule(message: "accession rollup needs this field"),
                AccessionRollupRequiredEncounterIDRule(message: "accession rollup needs this field"),
                AccessionRollupDiscountRangeRule(min: 9.8, max: 1176.4),
            ]
        )
    }
}
