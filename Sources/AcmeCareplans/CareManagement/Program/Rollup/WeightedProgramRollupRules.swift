import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted program rollup must pass. Check returns its problems, or none.
    protocol WeightedProgramRollupRule {
        func check(_ item: WeightedProgramRollup) -> [String]
    }

    final class WeightedProgramRollupPinnedGuardRule: WeightedProgramRollupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedProgramRollup) -> [String] {
            if item.pinned && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class WeightedProgramRollupRequiredCodeRule: WeightedProgramRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedProgramRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedProgramRollupCodeLengthRule: WeightedProgramRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedProgramRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedProgramRollupRequiredBedRule: WeightedProgramRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedProgramRollup) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted program rollup.
    final class WeightedProgramRollupValidator {
        var rules: [any WeightedProgramRollupRule]

        init(rules: [any WeightedProgramRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedProgramRollup) -> [String] {
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

        func requireValid(_ item: WeightedProgramRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedProgramRollup]) -> [String: [String]] {
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

    static func defaultWeightedProgramRollupValidator() -> WeightedProgramRollupValidator {
        return WeightedProgramRollupValidator(
            rules: [
                WeightedProgramRollupPinnedGuardRule(limit: 120),
                WeightedProgramRollupRequiredCodeRule(message: "weighted program rollup needs this field"),
                WeightedProgramRollupCodeLengthRule(maxLength: 120),
                WeightedProgramRollupRequiredBedRule(message: "weighted program rollup needs this field"),
            ]
        )
    }
}
