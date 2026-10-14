import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning summary must pass. Check returns its problems, or none.
    protocol CleaningSummaryRule {
        func check(_ item: CleaningSummary) -> [String]
    }

    final class CleaningSummaryRequiredCodeRule: CleaningSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningSummaryAllowedLabelRule: CleaningSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class CleaningSummaryLabelLengthRule: CleaningSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning summary.
    final class CleaningSummaryValidator {
        var rules: [any CleaningSummaryRule]

        init(rules: [any CleaningSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningSummary) -> [String] {
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

        func requireValid(_ item: CleaningSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningSummary]) -> [String: [String]] {
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

    static func defaultCleaningSummaryValidator() -> CleaningSummaryValidator {
        return CleaningSummaryValidator(
            rules: [
                CleaningSummaryRequiredCodeRule(message: "cleaning summary needs a value"),
                CleaningSummaryAllowedLabelRule(allowed: ["primary"]),
                CleaningSummaryLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
