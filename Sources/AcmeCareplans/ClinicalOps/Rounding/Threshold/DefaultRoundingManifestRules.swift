import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default rounding manifest must pass. Check returns its problems, or none.
    protocol DefaultRoundingManifestRule {
        func check(_ item: DefaultRoundingManifest) -> [String]
    }

    final class DefaultRoundingManifestMinimumRangeRule: DefaultRoundingManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultRoundingManifest) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DefaultRoundingManifestSourceLengthRule: DefaultRoundingManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRoundingManifest) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRoundingManifestActiveGuardRule: DefaultRoundingManifestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultRoundingManifest) -> [String] {
            if item.active && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a default rounding manifest.
    final class DefaultRoundingManifestValidator {
        var rules: [any DefaultRoundingManifestRule]

        init(rules: [any DefaultRoundingManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRoundingManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultRoundingManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRoundingManifest]) -> [String: [String]] {
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

    static func defaultDefaultRoundingManifestValidator() -> DefaultRoundingManifestValidator {
        return DefaultRoundingManifestValidator(
            rules: [
                DefaultRoundingManifestMinimumRangeRule(min: 3.0, max: 805.8),
                DefaultRoundingManifestSourceLengthRule(maxLength: 64),
                DefaultRoundingManifestActiveGuardRule(limit: 4.6),
            ]
        )
    }
}
