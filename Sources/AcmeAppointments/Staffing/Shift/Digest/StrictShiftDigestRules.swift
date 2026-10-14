import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict shift digest must pass. Check returns its problems, or none.
    protocol StrictShiftDigestRule {
        func check(_ item: StrictShiftDigest) -> [String]
    }

    final class StrictShiftDigestRequiredAllergyRule: StrictShiftDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictShiftDigest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictShiftDigestTitleLengthRule: StrictShiftDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictShiftDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictShiftDigestAllergyLengthRule: StrictShiftDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictShiftDigest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict shift digest.
    final class StrictShiftDigestValidator {
        var rules: [any StrictShiftDigestRule]

        init(rules: [any StrictShiftDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictShiftDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictShiftDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictShiftDigest]) -> [String: [String]] {
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

    static func defaultStrictShiftDigestValidator() -> StrictShiftDigestValidator {
        return StrictShiftDigestValidator(
            rules: [
                StrictShiftDigestRequiredAllergyRule(message: "strict shift digest needs this field"),
                StrictShiftDigestTitleLengthRule(maxLength: 64),
                StrictShiftDigestAllergyLengthRule(maxLength: 80),
            ]
        )
    }
}
