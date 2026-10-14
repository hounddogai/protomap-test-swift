import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback task manifest must pass. Check returns its problems, or none.
    protocol FallbackTaskManifestRule {
        func check(_ item: FallbackTaskManifest) -> [String]
    }

    final class FallbackTaskManifestRequiredNameRule: FallbackTaskManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTaskManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackTaskManifestAllergyLengthRule: FallbackTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackTaskManifest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackTaskManifestCodeLengthRule: FallbackTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackTaskManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackTaskManifestMarginRangeRule: FallbackTaskManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackTaskManifest) -> [String] {
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

    final class FallbackTaskManifestNameLengthRule: FallbackTaskManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackTaskManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback task manifest.
    final class FallbackTaskManifestValidator {
        var rules: [any FallbackTaskManifestRule]

        init(rules: [any FallbackTaskManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackTaskManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackTaskManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackTaskManifest]) -> [String: [String]] {
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

    static func defaultFallbackTaskManifestValidator() -> FallbackTaskManifestValidator {
        return FallbackTaskManifestValidator(
            rules: [
                FallbackTaskManifestRequiredNameRule(message: "fallback task manifest needs this field"),
                FallbackTaskManifestAllergyLengthRule(maxLength: 255),
                FallbackTaskManifestCodeLengthRule(maxLength: 80),
                FallbackTaskManifestMarginRangeRule(min: 2.9, max: 4507.0),
                FallbackTaskManifestNameLengthRule(maxLength: 255),
            ]
        )
    }
}
