import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict dispense target must pass. Check returns its problems, or none.
    protocol StrictDispenseTargetRule {
        func check(_ item: StrictDispenseTarget) -> [String]
    }

    final class StrictDispenseTargetCodePrefixRule: StrictDispenseTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictDispenseTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictDispenseTargetAllowedCodeRule: StrictDispenseTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictDispenseTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is not allowed"]
            }
            return []
        }
    }

    final class StrictDispenseTargetRequiredPhoneRule: StrictDispenseTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDispenseTarget) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictDispenseTargetLocaleLengthRule: StrictDispenseTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDispenseTarget) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDispenseTargetActiveGuardRule: StrictDispenseTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictDispenseTarget) -> [String] {
            if item.active && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a strict dispense target.
    final class StrictDispenseTargetValidator {
        var rules: [any StrictDispenseTargetRule]

        init(rules: [any StrictDispenseTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDispenseTarget) -> [String] {
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

        func requireValid(_ item: StrictDispenseTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDispenseTarget]) -> [String: [String]] {
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

    static func defaultStrictDispenseTargetValidator() -> StrictDispenseTargetValidator {
        return StrictDispenseTargetValidator(
            rules: [
                StrictDispenseTargetCodePrefixRule(prefix: "Q"),
                StrictDispenseTargetAllowedCodeRule(allowed: ["weighted", "global"]),
                StrictDispenseTargetRequiredPhoneRule(message: "strict dispense target needs this field"),
                StrictDispenseTargetLocaleLengthRule(maxLength: 80),
                StrictDispenseTargetActiveGuardRule(limit: 255),
            ]
        )
    }
}
