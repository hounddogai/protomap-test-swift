import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation mapping must pass. Check returns its problems, or none.
    protocol RevocationMappingRule {
        func check(_ item: RevocationMapping) -> [String]
    }

    final class RevocationMappingRequiredCategoryRule: RevocationMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationMapping) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationMappingRequiredNameRule: RevocationMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationMappingMinimumRangeRule: RevocationMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationMapping) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationMappingAllowedSegmentRule: RevocationMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RevocationMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is blocked"]
            }
            return []
        }
    }

    final class RevocationMappingCategoryLengthRule: RevocationMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationMapping) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation mapping.
    final class RevocationMappingValidator {
        var rules: [any RevocationMappingRule]

        init(rules: [any RevocationMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationMapping) -> [String] {
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

        func requireValid(_ item: RevocationMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationMapping]) -> [String: [String]] {
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

    static func defaultRevocationMappingValidator() -> RevocationMappingValidator {
        return RevocationMappingValidator(
            rules: [
                RevocationMappingRequiredCategoryRule(message: "revocation mapping needs a value"),
                RevocationMappingRequiredNameRule(message: "revocation mapping needs this field"),
                RevocationMappingMinimumRangeRule(min: 1.8, max: 4514.6),
                RevocationMappingAllowedSegmentRule(allowed: ["seasonal", "manual"]),
                RevocationMappingCategoryLengthRule(maxLength: 255),
            ]
        )
    }
}
