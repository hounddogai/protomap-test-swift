import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy formulary rollup must pass. Check returns its problems, or none.
    protocol LegacyFormularyRollupRule {
        func check(_ item: LegacyFormularyRollup) -> [String]
    }

    final class LegacyFormularyRollupPinnedGuardRule: LegacyFormularyRollupRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyFormularyRollup) -> [String] {
            if item.pinned && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LegacyFormularyRollupLabelLengthRule: LegacyFormularyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFormularyRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyFormularyRollupTimezoneLengthRule: LegacyFormularyRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyFormularyRollup) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy formulary rollup.
    final class LegacyFormularyRollupValidator {
        var rules: [any LegacyFormularyRollupRule]

        init(rules: [any LegacyFormularyRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyFormularyRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyFormularyRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyFormularyRollup]) -> [String: [String]] {
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

    static func defaultLegacyFormularyRollupValidator() -> LegacyFormularyRollupValidator {
        return LegacyFormularyRollupValidator(
            rules: [
                LegacyFormularyRollupPinnedGuardRule(limit: 16),
                LegacyFormularyRollupLabelLengthRule(maxLength: 32),
                LegacyFormularyRollupTimezoneLengthRule(maxLength: 1000),
            ]
        )
    }
}
