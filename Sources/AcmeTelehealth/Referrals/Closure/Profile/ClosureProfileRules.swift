import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure profile must pass. Check returns its problems, or none.
    protocol ClosureProfileRule {
        func check(_ item: ClosureProfile) -> [String]
    }

    final class ClosureProfileRequiredUnitRule: ClosureProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureProfile) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureProfileAllowedPhoneRule: ClosureProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is too long"]
            }
            return []
        }
    }

    final class ClosureProfileRequiredTitleRule: ClosureProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureProfile) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureProfileCodePrefixRule: ClosureProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureProfilePhoneLengthRule: ClosureProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureProfile) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureProfileBatchSizeRangeRule: ClosureProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureProfile) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a closure profile.
    final class ClosureProfileValidator {
        var rules: [any ClosureProfileRule]

        init(rules: [any ClosureProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureProfile) -> [String] {
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

        func requireValid(_ item: ClosureProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureProfile]) -> [String: [String]] {
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

    static func defaultClosureProfileValidator() -> ClosureProfileValidator {
        return ClosureProfileValidator(
            rules: [
                ClosureProfileRequiredUnitRule(message: "closure profile needs this field"),
                ClosureProfileAllowedPhoneRule(allowed: ["scheduled", "regional"]),
                ClosureProfileRequiredTitleRule(message: "closure profile needs a value"),
                ClosureProfileCodePrefixRule(prefix: "REF"),
                ClosureProfilePhoneLengthRule(maxLength: 16),
                ClosureProfileBatchSizeRangeRule(min: 80, max: 255),
            ]
        )
    }
}
