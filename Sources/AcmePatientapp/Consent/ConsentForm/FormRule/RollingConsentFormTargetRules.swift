import AcmePlatform
import Foundation

extension Consent {
    /// A rule a rolling consent form target must pass. Check returns its problems, or none.
    protocol RollingConsentFormTargetRule {
        func check(_ item: RollingConsentFormTarget) -> [String]
    }

    final class RollingConsentFormTargetRequiredPhoneRule: RollingConsentFormTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormTarget) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormTargetRequiredContactEmailRule: RollingConsentFormTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormTarget) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormTargetPhoneLengthRule: RollingConsentFormTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingConsentFormTarget) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingConsentFormTargetRequiredCodeRule: RollingConsentFormTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingConsentFormTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingConsentFormTargetQuantityRangeRule: RollingConsentFormTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingConsentFormTarget) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingConsentFormTargetAllowedNameRule: RollingConsentFormTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingConsentFormTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling consent form target.
    final class RollingConsentFormTargetValidator {
        var rules: [any RollingConsentFormTargetRule]

        init(rules: [any RollingConsentFormTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingConsentFormTarget) -> [String] {
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

        func requireValid(_ item: RollingConsentFormTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingConsentFormTarget]) -> [String: [String]] {
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

    static func defaultRollingConsentFormTargetValidator() -> RollingConsentFormTargetValidator {
        return RollingConsentFormTargetValidator(
            rules: [
                RollingConsentFormTargetRequiredPhoneRule(message: "rolling consent form target needs an entry"),
                RollingConsentFormTargetRequiredContactEmailRule(message: "rolling consent form target needs a value"),
                RollingConsentFormTargetPhoneLengthRule(maxLength: 1000),
                RollingConsentFormTargetRequiredCodeRule(message: "rolling consent form target needs a value"),
                RollingConsentFormTargetQuantityRangeRule(min: 1000, max: 1000),
                RollingConsentFormTargetAllowedNameRule(allowed: ["adaptive"]),
            ]
        )
    }
}
