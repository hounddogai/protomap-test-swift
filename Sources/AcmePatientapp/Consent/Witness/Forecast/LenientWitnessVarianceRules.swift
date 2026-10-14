import AcmePlatform
import Foundation

extension Consent {
    /// A rule a lenient witness variance must pass. Check returns its problems, or none.
    protocol LenientWitnessVarianceRule {
        func check(_ item: LenientWitnessVariance) -> [String]
    }

    final class LenientWitnessVarianceTagsLimitRule: LenientWitnessVarianceRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: LenientWitnessVariance) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class LenientWitnessVarianceRequiredAllergyRule: LenientWitnessVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientWitnessVariance) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientWitnessVarianceNameLengthRule: LenientWitnessVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientWitnessVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient witness variance.
    final class LenientWitnessVarianceValidator {
        var rules: [any LenientWitnessVarianceRule]

        init(rules: [any LenientWitnessVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientWitnessVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientWitnessVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientWitnessVariance]) -> [String: [String]] {
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

    static func defaultLenientWitnessVarianceValidator() -> LenientWitnessVarianceValidator {
        return LenientWitnessVarianceValidator(
            rules: [
                LenientWitnessVarianceTagsLimitRule(maxCount: 3600, banned: ["lenient"]),
                LenientWitnessVarianceRequiredAllergyRule(message: "lenient witness variance needs an entry"),
                LenientWitnessVarianceNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
