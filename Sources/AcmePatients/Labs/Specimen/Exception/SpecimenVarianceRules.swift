import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen variance must pass. Check returns its problems, or none.
    protocol SpecimenVarianceRule {
        func check(_ item: SpecimenVariance) -> [String]
    }

    final class SpecimenVarianceAllowedCodeRule: SpecimenVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class SpecimenVarianceRequiredAllergyRule: SpecimenVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenVariance) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenVarianceRequiredCodeRule: SpecimenVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenVarianceBedLengthRule: SpecimenVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenVariance) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen variance.
    final class SpecimenVarianceValidator {
        var rules: [any SpecimenVarianceRule]

        init(rules: [any SpecimenVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenVariance) -> [String] {
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

        func requireValid(_ item: SpecimenVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenVariance]) -> [String: [String]] {
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

    static func defaultSpecimenVarianceValidator() -> SpecimenVarianceValidator {
        return SpecimenVarianceValidator(
            rules: [
                SpecimenVarianceAllowedCodeRule(allowed: ["pending", "regional", "primary"]),
                SpecimenVarianceRequiredAllergyRule(message: "specimen variance needs a value"),
                SpecimenVarianceRequiredCodeRule(message: "specimen variance needs an entry"),
                SpecimenVarianceBedLengthRule(maxLength: 16),
            ]
        )
    }
}
