import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient program variance must pass. Check returns its problems, or none.
    protocol LenientProgramVarianceRule {
        func check(_ item: LenientProgramVariance) -> [String]
    }

    final class LenientProgramVarianceNameLengthRule: LenientProgramVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientProgramVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientProgramVarianceRequiredCodeRule: LenientProgramVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProgramVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProgramVarianceRequiredNameRule: LenientProgramVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientProgramVariance) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientProgramVarianceQuantityRangeRule: LenientProgramVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProgramVariance) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientProgramVarianceRevisionRangeRule: LenientProgramVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientProgramVariance) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientProgramVarianceArchivedGuardRule: LenientProgramVarianceRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: LenientProgramVariance) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient program variance.
    final class LenientProgramVarianceValidator {
        var rules: [any LenientProgramVarianceRule]

        init(rules: [any LenientProgramVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientProgramVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientProgramVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientProgramVariance]) -> [String: [String]] {
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

    static func defaultLenientProgramVarianceValidator() -> LenientProgramVarianceValidator {
        return LenientProgramVarianceValidator(
            rules: [
                LenientProgramVarianceNameLengthRule(maxLength: 16),
                LenientProgramVarianceRequiredCodeRule(message: "lenient program variance needs this field"),
                LenientProgramVarianceRequiredNameRule(message: "lenient program variance needs an entry"),
                LenientProgramVarianceQuantityRangeRule(min: 1000, max: 3600),
                LenientProgramVarianceRevisionRangeRule(min: 16, max: 3600),
                LenientProgramVarianceArchivedGuardRule(limit: 8.2),
            ]
        )
    }
}
