import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback rounding manifest must pass. Check returns its problems, or none.
    protocol FallbackRoundingManifestRule {
        func check(_ item: FallbackRoundingManifest) -> [String]
    }

    final class FallbackRoundingManifestTitleLengthRule: FallbackRoundingManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRoundingManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackRoundingManifestRequiredCodeRule: FallbackRoundingManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRoundingManifestRequiredTitleRule: FallbackRoundingManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingManifest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRoundingManifestRequiredLabelRule: FallbackRoundingManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRoundingManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback rounding manifest.
    final class FallbackRoundingManifestValidator {
        var rules: [any FallbackRoundingManifestRule]

        init(rules: [any FallbackRoundingManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRoundingManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackRoundingManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRoundingManifest]) -> [String: [String]] {
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

    static func defaultFallbackRoundingManifestValidator() -> FallbackRoundingManifestValidator {
        return FallbackRoundingManifestValidator(
            rules: [
                FallbackRoundingManifestTitleLengthRule(maxLength: 120),
                FallbackRoundingManifestRequiredCodeRule(message: "fallback rounding manifest needs this field"),
                FallbackRoundingManifestRequiredTitleRule(message: "fallback rounding manifest needs this field"),
                FallbackRoundingManifestRequiredLabelRule(message: "fallback rounding manifest needs this field"),
            ]
        )
    }
}
