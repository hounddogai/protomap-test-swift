import AcmePlatform
import Foundation

extension Consent {
    /// A rule a adaptive consent form allocation must pass. Check returns its problems, or none.
    protocol AdaptiveConsentFormAllocationRule {
        func check(_ item: AdaptiveConsentFormAllocation) -> [String]
    }

    final class AdaptiveConsentFormAllocationCodeLengthRule: AdaptiveConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormAllocation) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormAllocationAllergyLengthRule: AdaptiveConsentFormAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveConsentFormAllocation) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveConsentFormAllocationCapacityRangeRule: AdaptiveConsentFormAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveConsentFormAllocation) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveConsentFormAllocationRequiredNameRule: AdaptiveConsentFormAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveConsentFormAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveConsentFormAllocationRequiredAllergyRule: AdaptiveConsentFormAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveConsentFormAllocation) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveConsentFormAllocationCodePrefixRule: AdaptiveConsentFormAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveConsentFormAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive consent form allocation.
    final class AdaptiveConsentFormAllocationValidator {
        var rules: [any AdaptiveConsentFormAllocationRule]

        init(rules: [any AdaptiveConsentFormAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveConsentFormAllocation) -> [String] {
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

        func requireValid(_ item: AdaptiveConsentFormAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveConsentFormAllocation]) -> [String: [String]] {
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

    static func defaultAdaptiveConsentFormAllocationValidator() -> AdaptiveConsentFormAllocationValidator {
        return AdaptiveConsentFormAllocationValidator(
            rules: [
                AdaptiveConsentFormAllocationCodeLengthRule(maxLength: 255),
                AdaptiveConsentFormAllocationAllergyLengthRule(maxLength: 80),
                AdaptiveConsentFormAllocationCapacityRangeRule(min: 32, max: 1000),
                AdaptiveConsentFormAllocationRequiredNameRule(
                    message: "adaptive consent form allocation needs an entry"
                ),
                AdaptiveConsentFormAllocationRequiredAllergyRule(
                    message: "adaptive consent form allocation needs an entry"
                ),
                AdaptiveConsentFormAllocationCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
