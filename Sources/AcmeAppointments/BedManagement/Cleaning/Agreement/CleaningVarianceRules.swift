import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning variance must pass. Check returns its problems, or none.
    protocol CleaningVarianceRule {
        func check(_ item: CleaningVariance) -> [String]
    }

    final class CleaningVarianceLabelLengthRule: CleaningVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningVarianceRequiredLabelRule: CleaningVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningVarianceCodePrefixRule: CleaningVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning variance.
    final class CleaningVarianceValidator {
        var rules: [any CleaningVarianceRule]

        init(rules: [any CleaningVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningVariance) -> [String] {
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

        func requireValid(_ item: CleaningVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningVariance]) -> [String: [String]] {
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

    static func defaultCleaningVarianceValidator() -> CleaningVarianceValidator {
        return CleaningVarianceValidator(
            rules: [
                CleaningVarianceLabelLengthRule(maxLength: 32),
                CleaningVarianceRequiredLabelRule(message: "cleaning variance needs a value"),
                CleaningVarianceCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
