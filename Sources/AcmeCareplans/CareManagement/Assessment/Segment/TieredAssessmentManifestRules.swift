import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered assessment manifest must pass. Check returns its problems, or none.
    protocol TieredAssessmentManifestRule {
        func check(_ item: TieredAssessmentManifest) -> [String]
    }

    final class TieredAssessmentManifestRequiredCodeRule: TieredAssessmentManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredAssessmentManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredAssessmentManifestAmountRangeRule: TieredAssessmentManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredAssessmentManifest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredAssessmentManifestCodePrefixRule: TieredAssessmentManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredAssessmentManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered assessment manifest.
    final class TieredAssessmentManifestValidator {
        var rules: [any TieredAssessmentManifestRule]

        init(rules: [any TieredAssessmentManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredAssessmentManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredAssessmentManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredAssessmentManifest]) -> [String: [String]] {
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

    static func defaultTieredAssessmentManifestValidator() -> TieredAssessmentManifestValidator {
        return TieredAssessmentManifestValidator(
            rules: [
                TieredAssessmentManifestRequiredCodeRule(message: "tiered assessment manifest needs an entry"),
                TieredAssessmentManifestAmountRangeRule(min: 10.0, max: 2063.3),
                TieredAssessmentManifestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
