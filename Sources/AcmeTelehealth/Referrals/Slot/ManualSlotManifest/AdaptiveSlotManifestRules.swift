import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive slot manifest must pass. Check returns its problems, or none.
    protocol AdaptiveSlotManifestRule {
        func check(_ item: AdaptiveSlotManifest) -> [String]
    }

    final class AdaptiveSlotManifestRequiredNameRule: AdaptiveSlotManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveSlotManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveSlotManifestCeilingRangeRule: AdaptiveSlotManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSlotManifest) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveSlotManifestTitleLengthRule: AdaptiveSlotManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSlotManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSlotManifestNameLengthRule: AdaptiveSlotManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveSlotManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveSlotManifestAllowedTitleRule: AdaptiveSlotManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptiveSlotManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class AdaptiveSlotManifestMarginRangeRule: AdaptiveSlotManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveSlotManifest) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive slot manifest.
    final class AdaptiveSlotManifestValidator {
        var rules: [any AdaptiveSlotManifestRule]

        init(rules: [any AdaptiveSlotManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveSlotManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveSlotManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveSlotManifest]) -> [String: [String]] {
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

    static func defaultAdaptiveSlotManifestValidator() -> AdaptiveSlotManifestValidator {
        return AdaptiveSlotManifestValidator(
            rules: [
                AdaptiveSlotManifestRequiredNameRule(message: "adaptive slot manifest needs an entry"),
                AdaptiveSlotManifestCeilingRangeRule(min: 7.1, max: 2377.6),
                AdaptiveSlotManifestTitleLengthRule(maxLength: 1000),
                AdaptiveSlotManifestNameLengthRule(maxLength: 1000),
                AdaptiveSlotManifestAllowedTitleRule(allowed: ["seasonal", "weighted"]),
                AdaptiveSlotManifestMarginRangeRule(min: 4.8, max: 1123.5),
            ]
        )
    }
}
