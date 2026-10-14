import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a adaptive task manifest must pass. Check returns its problems, or none.
    protocol AdaptiveTaskManifestRule {
        func check(_ item: AdaptiveTaskManifest) -> [String]
    }

    final class AdaptiveTaskManifestRefillsRangeRule: AdaptiveTaskManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveTaskManifest) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveTaskManifestPayerLengthRule: AdaptiveTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveTaskManifest) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveTaskManifestAllowedTitleRule: AdaptiveTaskManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveTaskManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is below minimum"]
            }
            return []
        }
    }

    final class AdaptiveTaskManifestFloorValueRangeRule: AdaptiveTaskManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveTaskManifest) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive task manifest.
    final class AdaptiveTaskManifestValidator {
        var rules: [any AdaptiveTaskManifestRule]

        init(rules: [any AdaptiveTaskManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveTaskManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveTaskManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveTaskManifest]) -> [String: [String]] {
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

    static func defaultAdaptiveTaskManifestValidator() -> AdaptiveTaskManifestValidator {
        return AdaptiveTaskManifestValidator(
            rules: [
                AdaptiveTaskManifestRefillsRangeRule(min: 80, max: 86400),
                AdaptiveTaskManifestPayerLengthRule(maxLength: 32),
                AdaptiveTaskManifestAllowedTitleRule(allowed: ["pending", "manual"]),
                AdaptiveTaskManifestFloorValueRangeRule(min: 1.4, max: 276.7),
            ]
        )
    }
}
