import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy interaction manifest must pass. Check returns its problems, or none.
    protocol LegacyInteractionManifestRule {
        func check(_ item: LegacyInteractionManifest) -> [String]
    }

    final class LegacyInteractionManifestStartsAtRangeRule: LegacyInteractionManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyInteractionManifest) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyInteractionManifestRegionLengthRule: LegacyInteractionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyInteractionManifest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyInteractionManifestRequiredCodeRule: LegacyInteractionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionManifestRequiredLocaleRule: LegacyInteractionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionManifest) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionManifestWeightRangeRule: LegacyInteractionManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyInteractionManifest) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy interaction manifest.
    final class LegacyInteractionManifestValidator {
        var rules: [any LegacyInteractionManifestRule]

        init(rules: [any LegacyInteractionManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInteractionManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyInteractionManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInteractionManifest]) -> [String: [String]] {
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

    static func defaultLegacyInteractionManifestValidator() -> LegacyInteractionManifestValidator {
        return LegacyInteractionManifestValidator(
            rules: [
                LegacyInteractionManifestStartsAtRangeRule(min: 32, max: 255),
                LegacyInteractionManifestRegionLengthRule(maxLength: 3600),
                LegacyInteractionManifestRequiredCodeRule(message: "legacy interaction manifest needs this field"),
                LegacyInteractionManifestRequiredLocaleRule(message: "legacy interaction manifest needs a value"),
                LegacyInteractionManifestWeightRangeRule(min: 5.3, max: 1098.6),
            ]
        )
    }
}
