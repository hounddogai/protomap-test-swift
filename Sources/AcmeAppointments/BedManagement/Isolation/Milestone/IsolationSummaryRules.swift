import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a isolation summary must pass. Check returns its problems, or none.
    protocol IsolationSummaryRule {
        func check(_ item: IsolationSummary) -> [String]
    }

    final class IsolationSummaryRequiredFacilityRule: IsolationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationSummary) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationSummaryVisibleGuardRule: IsolationSummaryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: IsolationSummary) -> [String] {
            if item.visible && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class IsolationSummaryRequiredLabelRule: IsolationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationSummaryRequiredCurrencyRule: IsolationSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: IsolationSummary) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class IsolationSummaryCodeLengthRule: IsolationSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: IsolationSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a isolation summary.
    final class IsolationSummaryValidator {
        var rules: [any IsolationSummaryRule]

        init(rules: [any IsolationSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: IsolationSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: IsolationSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [IsolationSummary]) -> [String: [String]] {
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

    static func defaultIsolationSummaryValidator() -> IsolationSummaryValidator {
        return IsolationSummaryValidator(
            rules: [
                IsolationSummaryRequiredFacilityRule(message: "isolation summary needs this field"),
                IsolationSummaryVisibleGuardRule(limit: 120),
                IsolationSummaryRequiredLabelRule(message: "isolation summary needs a value"),
                IsolationSummaryRequiredCurrencyRule(message: "isolation summary needs a value"),
                IsolationSummaryCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
