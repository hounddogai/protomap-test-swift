import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap exception must pass. Check returns its problems, or none.
    protocol CareGapExceptionRule {
        func check(_ item: CareGapException) -> [String]
    }

    final class CareGapExceptionVersionRangeRule: CareGapExceptionRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapException) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareGapExceptionCodePrefixRule: CareGapExceptionRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareGapException) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareGapExceptionRequiredAllergyRule: CareGapExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapException) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapExceptionRequiredCodeRule: CareGapExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapException) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapExceptionRequiredDescriptionRule: CareGapExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapException) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap exception.
    final class CareGapExceptionValidator {
        var rules: [any CareGapExceptionRule]

        init(rules: [any CareGapExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapException) -> [String] {
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

        func requireValid(_ item: CareGapException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapException]) -> [String: [String]] {
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

    static func defaultCareGapExceptionValidator() -> CareGapExceptionValidator {
        return CareGapExceptionValidator(
            rules: [
                CareGapExceptionVersionRangeRule(min: 16, max: 64),
                CareGapExceptionCodePrefixRule(prefix: "REF"),
                CareGapExceptionRequiredAllergyRule(message: "care gap exception needs this field"),
                CareGapExceptionRequiredCodeRule(message: "care gap exception needs an entry"),
                CareGapExceptionRequiredDescriptionRule(message: "care gap exception needs this field"),
            ]
        )
    }
}
