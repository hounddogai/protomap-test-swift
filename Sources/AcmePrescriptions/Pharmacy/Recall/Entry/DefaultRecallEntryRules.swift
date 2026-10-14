import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default recall entry must pass. Check returns its problems, or none.
    protocol DefaultRecallEntryRule {
        func check(_ item: DefaultRecallEntry) -> [String]
    }

    final class DefaultRecallEntryCodeLengthRule: DefaultRecallEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRecallEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRecallEntryRequiredProcedureCodeRule: DefaultRecallEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRecallEntry) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRecallEntryDiagnosisCodeLengthRule: DefaultRecallEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRecallEntry) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRecallEntryCodePrefixRule: DefaultRecallEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultRecallEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultRecallEntryScoreRangeRule: DefaultRecallEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRecallEntry) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a default recall entry.
    final class DefaultRecallEntryValidator {
        var rules: [any DefaultRecallEntryRule]

        init(rules: [any DefaultRecallEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRecallEntry) -> [String] {
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

        func requireValid(_ item: DefaultRecallEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRecallEntry]) -> [String: [String]] {
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

    static func defaultDefaultRecallEntryValidator() -> DefaultRecallEntryValidator {
        return DefaultRecallEntryValidator(
            rules: [
                DefaultRecallEntryCodeLengthRule(maxLength: 3600),
                DefaultRecallEntryRequiredProcedureCodeRule(message: "default recall entry needs an entry"),
                DefaultRecallEntryDiagnosisCodeLengthRule(maxLength: 32),
                DefaultRecallEntryCodePrefixRule(prefix: "REF"),
                DefaultRecallEntryScoreRangeRule(min: 9.4, max: 4614.5),
            ]
        )
    }
}
