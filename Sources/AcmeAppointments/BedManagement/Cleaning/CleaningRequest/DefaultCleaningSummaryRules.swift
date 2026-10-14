import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default cleaning summary must pass. Check returns its problems, or none.
    protocol DefaultCleaningSummaryRule {
        func check(_ item: DefaultCleaningSummary) -> [String]
    }

    final class DefaultCleaningSummaryRequiredSpecialtyRule: DefaultCleaningSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultCleaningSummary) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultCleaningSummarySourceLengthRule: DefaultCleaningSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCleaningSummary) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCleaningSummaryCodePrefixRule: DefaultCleaningSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCleaningSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a default cleaning summary.
    final class DefaultCleaningSummaryValidator {
        var rules: [any DefaultCleaningSummaryRule]

        init(rules: [any DefaultCleaningSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCleaningSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultCleaningSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCleaningSummary]) -> [String: [String]] {
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

    static func defaultDefaultCleaningSummaryValidator() -> DefaultCleaningSummaryValidator {
        return DefaultCleaningSummaryValidator(
            rules: [
                DefaultCleaningSummaryRequiredSpecialtyRule(message: "default cleaning summary needs an entry"),
                DefaultCleaningSummarySourceLengthRule(maxLength: 64),
                DefaultCleaningSummaryCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
