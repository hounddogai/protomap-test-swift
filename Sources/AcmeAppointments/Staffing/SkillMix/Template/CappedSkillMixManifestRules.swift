import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a capped skill mix manifest must pass. Check returns its problems, or none.
    protocol CappedSkillMixManifestRule {
        func check(_ item: CappedSkillMixManifest) -> [String]
    }

    final class CappedSkillMixManifestCodePrefixRule: CappedSkillMixManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedSkillMixManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedSkillMixManifestSummaryLengthRule: CappedSkillMixManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedSkillMixManifest) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedSkillMixManifestQuantityRangeRule: CappedSkillMixManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedSkillMixManifest) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped skill mix manifest.
    final class CappedSkillMixManifestValidator {
        var rules: [any CappedSkillMixManifestRule]

        init(rules: [any CappedSkillMixManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedSkillMixManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedSkillMixManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedSkillMixManifest]) -> [String: [String]] {
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

    static func defaultCappedSkillMixManifestValidator() -> CappedSkillMixManifestValidator {
        return CappedSkillMixManifestValidator(
            rules: [
                CappedSkillMixManifestCodePrefixRule(prefix: "OPS"),
                CappedSkillMixManifestSummaryLengthRule(maxLength: 255),
                CappedSkillMixManifestQuantityRangeRule(min: 64, max: 86400),
            ]
        )
    }
}
