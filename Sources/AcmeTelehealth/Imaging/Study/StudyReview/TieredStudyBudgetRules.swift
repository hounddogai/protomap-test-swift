import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered study budget must pass. Check returns its problems, or none.
    protocol TieredStudyBudgetRule {
        func check(_ item: TieredStudyBudget) -> [String]
    }

    final class TieredStudyBudgetCopayRangeRule: TieredStudyBudgetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredStudyBudget) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredStudyBudgetTimezoneLengthRule: TieredStudyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudyBudget) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudyBudgetNameLengthRule: TieredStudyBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredStudyBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredStudyBudgetAllowedCodeRule: TieredStudyBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredStudyBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class TieredStudyBudgetCodePrefixRule: TieredStudyBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredStudyBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredStudyBudgetArchivedGuardRule: TieredStudyBudgetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredStudyBudget) -> [String] {
            if item.archived && (item.version > limit) {
                return ["version \(item.version) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered study budget.
    final class TieredStudyBudgetValidator {
        var rules: [any TieredStudyBudgetRule]

        init(rules: [any TieredStudyBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredStudyBudget) -> [String] {
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

        func requireValid(_ item: TieredStudyBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredStudyBudget]) -> [String: [String]] {
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

    static func defaultTieredStudyBudgetValidator() -> TieredStudyBudgetValidator {
        return TieredStudyBudgetValidator(
            rules: [
                TieredStudyBudgetCopayRangeRule(min: 8.4, max: 3540.5),
                TieredStudyBudgetTimezoneLengthRule(maxLength: 1000),
                TieredStudyBudgetNameLengthRule(maxLength: 1000),
                TieredStudyBudgetAllowedCodeRule(allowed: ["primary"]),
                TieredStudyBudgetCodePrefixRule(prefix: "OPS"),
                TieredStudyBudgetArchivedGuardRule(limit: 1000),
            ]
        )
    }
}
