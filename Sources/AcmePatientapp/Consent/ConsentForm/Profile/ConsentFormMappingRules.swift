import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form mapping must pass. Check returns its problems, or none.
    protocol ConsentFormMappingRule {
        func check(_ item: ConsentFormMapping) -> [String]
    }

    final class ConsentFormMappingAcuityRangeRule: ConsentFormMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormMapping) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ConsentFormMappingCodeLengthRule: ConsentFormMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormMapping) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormMappingAllowedDescriptionRule: ConsentFormMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ConsentFormMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is unknown"]
            }
            return []
        }
    }

    final class ConsentFormMappingRequiredCodeRule: ConsentFormMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormMappingDescriptionLengthRule: ConsentFormMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormMapping) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormMappingRequiredLabelRule: ConsentFormMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormMapping) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form mapping.
    final class ConsentFormMappingValidator {
        var rules: [any ConsentFormMappingRule]

        init(rules: [any ConsentFormMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormMapping]) -> [String: [String]] {
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

    static func defaultConsentFormMappingValidator() -> ConsentFormMappingValidator {
        return ConsentFormMappingValidator(
            rules: [
                ConsentFormMappingAcuityRangeRule(min: 16, max: 120),
                ConsentFormMappingCodeLengthRule(maxLength: 32),
                ConsentFormMappingAllowedDescriptionRule(allowed: ["pending", "tiered", "legacy"]),
                ConsentFormMappingRequiredCodeRule(message: "consent form mapping needs an entry"),
                ConsentFormMappingDescriptionLengthRule(maxLength: 80),
                ConsentFormMappingRequiredLabelRule(message: "consent form mapping needs an entry"),
            ]
        )
    }
}
