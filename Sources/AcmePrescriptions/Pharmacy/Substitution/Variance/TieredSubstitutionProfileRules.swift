import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a tiered substitution profile must pass. Check returns its problems, or none.
    protocol TieredSubstitutionProfileRule {
        func check(_ item: TieredSubstitutionProfile) -> [String]
    }

    final class TieredSubstitutionProfileVisibleGuardRule: TieredSubstitutionProfileRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredSubstitutionProfile) -> [String] {
            if item.visible && (item.score > limit) {
                return ["score \(item.score) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class TieredSubstitutionProfileSourceLengthRule: TieredSubstitutionProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSubstitutionProfile) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredSubstitutionProfileCodeLengthRule: TieredSubstitutionProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredSubstitutionProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered substitution profile.
    final class TieredSubstitutionProfileValidator {
        var rules: [any TieredSubstitutionProfileRule]

        init(rules: [any TieredSubstitutionProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredSubstitutionProfile) -> [String] {
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

        func requireValid(_ item: TieredSubstitutionProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredSubstitutionProfile]) -> [String: [String]] {
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

    static func defaultTieredSubstitutionProfileValidator() -> TieredSubstitutionProfileValidator {
        return TieredSubstitutionProfileValidator(
            rules: [
                TieredSubstitutionProfileVisibleGuardRule(limit: 1.2),
                TieredSubstitutionProfileSourceLengthRule(maxLength: 80),
                TieredSubstitutionProfileCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
