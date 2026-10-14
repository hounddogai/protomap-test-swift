import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language allocation must pass. Check returns its problems, or none.
    protocol LanguageAllocationRule {
        func check(_ item: LanguageAllocation) -> [String]
    }

    final class LanguageAllocationFacilityLengthRule: LanguageAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageAllocation) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LanguageAllocationCodePrefixRule: LanguageAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LanguageAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LanguageAllocationRequiredFacilityRule: LanguageAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageAllocation) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageAllocationUpdatedAtRangeRule: LanguageAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageAllocation) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LanguageAllocationCodeLengthRule: LanguageAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LanguageAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a language allocation.
    final class LanguageAllocationValidator {
        var rules: [any LanguageAllocationRule]

        init(rules: [any LanguageAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LanguageAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageAllocation]) -> [String: [String]] {
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

    static func defaultLanguageAllocationValidator() -> LanguageAllocationValidator {
        return LanguageAllocationValidator(
            rules: [
                LanguageAllocationFacilityLengthRule(maxLength: 120),
                LanguageAllocationCodePrefixRule(prefix: "Q"),
                LanguageAllocationRequiredFacilityRule(message: "language allocation needs this field"),
                LanguageAllocationUpdatedAtRangeRule(min: 16, max: 255),
                LanguageAllocationCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
