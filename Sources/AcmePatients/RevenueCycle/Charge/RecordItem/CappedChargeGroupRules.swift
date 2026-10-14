import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a capped charge group must pass. Check returns its problems, or none.
    protocol CappedChargeGroupRule {
        func check(_ item: CappedChargeGroup) -> [String]
    }

    final class CappedChargeGroupWardLengthRule: CappedChargeGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedChargeGroup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedChargeGroupRequiredTimezoneRule: CappedChargeGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedChargeGroup) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedChargeGroupCodePrefixRule: CappedChargeGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedChargeGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped charge group.
    final class CappedChargeGroupValidator {
        var rules: [any CappedChargeGroupRule]

        init(rules: [any CappedChargeGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedChargeGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedChargeGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedChargeGroup]) -> [String: [String]] {
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

    static func defaultCappedChargeGroupValidator() -> CappedChargeGroupValidator {
        return CappedChargeGroupValidator(
            rules: [
                CappedChargeGroupWardLengthRule(maxLength: 80),
                CappedChargeGroupRequiredTimezoneRule(message: "capped charge group needs a value"),
                CappedChargeGroupCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
