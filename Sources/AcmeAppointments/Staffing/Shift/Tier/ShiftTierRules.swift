import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift tier must pass. Check returns its problems, or none.
    protocol ShiftTierRule {
        func check(_ item: ShiftTier) -> [String]
    }

    final class ShiftTierPhoneLengthRule: ShiftTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftTier) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftTierCodeLengthRule: ShiftTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftTierAllowedCodeRule: ShiftTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ShiftTierRequiredExternalRefRule: ShiftTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftTier) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftTierExternalRefLengthRule: ShiftTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftTier) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift tier.
    final class ShiftTierValidator {
        var rules: [any ShiftTierRule]

        init(rules: [any ShiftTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ShiftTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftTier]) -> [String: [String]] {
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

    static func defaultShiftTierValidator() -> ShiftTierValidator {
        return ShiftTierValidator(
            rules: [
                ShiftTierPhoneLengthRule(maxLength: 86400),
                ShiftTierCodeLengthRule(maxLength: 3600),
                ShiftTierAllowedCodeRule(allowed: ["tiered"]),
                ShiftTierRequiredExternalRefRule(message: "shift tier needs this field"),
                ShiftTierExternalRefLengthRule(maxLength: 3600),
            ]
        )
    }
}
