import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional isolation draft must pass. Check returns its problems, or none.
    protocol RegionalIsolationDraftRule {
        func check(_ item: RegionalIsolationDraft) -> [String]
    }

    final class RegionalIsolationDraftAllowedNameRule: RegionalIsolationDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalIsolationDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class RegionalIsolationDraftCodeLengthRule: RegionalIsolationDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalIsolationDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalIsolationDraftMarginRangeRule: RegionalIsolationDraftRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalIsolationDraft) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional isolation draft.
    final class RegionalIsolationDraftValidator {
        var rules: [any RegionalIsolationDraftRule]

        init(rules: [any RegionalIsolationDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalIsolationDraft) -> [String] {
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

        func requireValid(_ item: RegionalIsolationDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalIsolationDraft]) -> [String: [String]] {
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

    static func defaultRegionalIsolationDraftValidator() -> RegionalIsolationDraftValidator {
        return RegionalIsolationDraftValidator(
            rules: [
                RegionalIsolationDraftAllowedNameRule(allowed: ["global", "default"]),
                RegionalIsolationDraftCodeLengthRule(maxLength: 86400),
                RegionalIsolationDraftMarginRangeRule(min: 9.2, max: 2297.6),
            ]
        )
    }
}
