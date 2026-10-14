import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient charge tier must pass. Check returns its problems, or none.
    protocol LenientChargeTierRule {
        func check(_ item: LenientChargeTier) -> [String]
    }

    final class LenientChargeTierRequiredCodeRule: LenientChargeTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientChargeTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientChargeTierAllowedExternalRefRule: LenientChargeTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientChargeTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is above maximum"]
            }
            return []
        }
    }

    final class LenientChargeTierRequiredLabelRule: LenientChargeTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientChargeTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientChargeTierCodeLengthRule: LenientChargeTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientChargeTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient charge tier.
    final class LenientChargeTierValidator {
        var rules: [any LenientChargeTierRule]

        init(rules: [any LenientChargeTierRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientChargeTier) -> [String] {
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

        func requireValid(_ item: LenientChargeTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientChargeTier]) -> [String: [String]] {
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

    static func defaultLenientChargeTierValidator() -> LenientChargeTierValidator {
        return LenientChargeTierValidator(
            rules: [
                LenientChargeTierRequiredCodeRule(message: "lenient charge tier needs an entry"),
                LenientChargeTierAllowedExternalRefRule(allowed: ["capped", "capped", "primary"]),
                LenientChargeTierRequiredLabelRule(message: "lenient charge tier needs a value"),
                LenientChargeTierCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
