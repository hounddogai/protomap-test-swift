import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution digest must pass. Check returns its problems, or none.
    protocol SubstitutionDigestRule {
        func check(_ item: SubstitutionDigest) -> [String]
    }

    final class SubstitutionDigestRequiredCategoryRule: SubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionDigest) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionDigestNameLengthRule: SubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionDigestCodeLengthRule: SubstitutionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionDigestRequiredCodeRule: SubstitutionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionDigestFloorValueRangeRule: SubstitutionDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionDigest) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionDigestAllowedCodeRule: SubstitutionDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution digest.
    final class SubstitutionDigestValidator {
        var rules: [any SubstitutionDigestRule]

        init(rules: [any SubstitutionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SubstitutionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionDigest]) -> [String: [String]] {
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

    static func defaultSubstitutionDigestValidator() -> SubstitutionDigestValidator {
        return SubstitutionDigestValidator(
            rules: [
                SubstitutionDigestRequiredCategoryRule(message: "substitution digest needs this field"),
                SubstitutionDigestNameLengthRule(maxLength: 120),
                SubstitutionDigestCodeLengthRule(maxLength: 255),
                SubstitutionDigestRequiredCodeRule(message: "substitution digest needs this field"),
                SubstitutionDigestFloorValueRangeRule(min: 4.1, max: 1345.3),
                SubstitutionDigestAllowedCodeRule(allowed: ["regional"]),
            ]
        )
    }
}
