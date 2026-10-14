import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure profile must pass. Check returns its problems, or none.
    protocol DisclosureProfileRule {
        func check(_ item: DisclosureProfile) -> [String]
    }

    final class DisclosureProfileAllergyLengthRule: DisclosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureProfile) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureProfileCodePrefixRule: DisclosureProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DisclosureProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DisclosureProfilePinnedGuardRule: DisclosureProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DisclosureProfile) -> [String] {
            if item.pinned && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class DisclosureProfileCodeLengthRule: DisclosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DisclosureProfileWeightRangeRule: DisclosureProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureProfile) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DisclosureProfileRequiredBedRule: DisclosureProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureProfile) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure profile.
    final class DisclosureProfileValidator {
        var rules: [any DisclosureProfileRule]

        init(rules: [any DisclosureProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureProfile) -> [String] {
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

        func requireValid(_ item: DisclosureProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureProfile]) -> [String: [String]] {
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

    static func defaultDisclosureProfileValidator() -> DisclosureProfileValidator {
        return DisclosureProfileValidator(
            rules: [
                DisclosureProfileAllergyLengthRule(maxLength: 120),
                DisclosureProfileCodePrefixRule(prefix: "ACM"),
                DisclosureProfilePinnedGuardRule(limit: 120),
                DisclosureProfileCodeLengthRule(maxLength: 32),
                DisclosureProfileWeightRangeRule(min: 5.7, max: 82.1),
                DisclosureProfileRequiredBedRule(message: "disclosure profile needs this field"),
            ]
        )
    }
}
