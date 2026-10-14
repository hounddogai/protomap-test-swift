import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy inventory manifest must pass. Check returns its problems, or none.
    protocol LegacyInventoryManifestRule {
        func check(_ item: LegacyInventoryManifest) -> [String]
    }

    final class LegacyInventoryManifestRequiredLabelRule: LegacyInventoryManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInventoryManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInventoryManifestRateRangeRule: LegacyInventoryManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyInventoryManifest) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyInventoryManifestAllowedReviewerRule: LegacyInventoryManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyInventoryManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy inventory manifest.
    final class LegacyInventoryManifestValidator {
        var rules: [any LegacyInventoryManifestRule]

        init(rules: [any LegacyInventoryManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInventoryManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyInventoryManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInventoryManifest]) -> [String: [String]] {
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

    static func defaultLegacyInventoryManifestValidator() -> LegacyInventoryManifestValidator {
        return LegacyInventoryManifestValidator(
            rules: [
                LegacyInventoryManifestRequiredLabelRule(message: "legacy inventory manifest needs an entry"),
                LegacyInventoryManifestRateRangeRule(min: 2.3, max: 4178.9),
                LegacyInventoryManifestAllowedReviewerRule(allowed: ["lenient", "scheduled", "lenient"]),
            ]
        )
    }
}
