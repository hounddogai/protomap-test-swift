import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict overtime summary must pass. Check returns its problems, or none.
    protocol StrictOvertimeSummaryRule {
        func check(_ item: StrictOvertimeSummary) -> [String]
    }

    final class StrictOvertimeSummaryAllowedTitleRule: StrictOvertimeSummaryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictOvertimeSummary) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class StrictOvertimeSummaryLabelLengthRule: StrictOvertimeSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOvertimeSummary) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictOvertimeSummaryRequiredLabelRule: StrictOvertimeSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictOvertimeSummary) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictOvertimeSummaryVisibleGuardRule: StrictOvertimeSummaryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictOvertimeSummary) -> [String] {
            if item.visible && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    /// Runs every rule of a strict overtime summary.
    final class StrictOvertimeSummaryValidator {
        var rules: [any StrictOvertimeSummaryRule]

        init(rules: [any StrictOvertimeSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOvertimeSummary) -> [String] {
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

        func requireValid(_ item: StrictOvertimeSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOvertimeSummary]) -> [String: [String]] {
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

    static func defaultStrictOvertimeSummaryValidator() -> StrictOvertimeSummaryValidator {
        return StrictOvertimeSummaryValidator(
            rules: [
                StrictOvertimeSummaryAllowedTitleRule(allowed: ["default"]),
                StrictOvertimeSummaryLabelLengthRule(maxLength: 32),
                StrictOvertimeSummaryRequiredLabelRule(message: "strict overtime summary needs this field"),
                StrictOvertimeSummaryVisibleGuardRule(limit: 80),
            ]
        )
    }
}
