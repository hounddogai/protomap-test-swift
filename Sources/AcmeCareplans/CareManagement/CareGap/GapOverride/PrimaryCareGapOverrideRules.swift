import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary care gap override must pass. Check returns its problems, or none.
    protocol PrimaryCareGapOverrideRule {
        func check(_ item: PrimaryCareGapOverride) -> [String]
    }

    final class PrimaryCareGapOverrideTitleLengthRule: PrimaryCareGapOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareGapOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCareGapOverrideRequiredTitleRule: PrimaryCareGapOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareGapOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareGapOverrideAllowedCodeRule: PrimaryCareGapOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryCareGapOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class PrimaryCareGapOverrideCodeLengthRule: PrimaryCareGapOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCareGapOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary care gap override.
    final class PrimaryCareGapOverrideValidator {
        var rules: [any PrimaryCareGapOverrideRule]

        init(rules: [any PrimaryCareGapOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCareGapOverride) -> [String] {
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

        func requireValid(_ item: PrimaryCareGapOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCareGapOverride]) -> [String: [String]] {
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

    static func defaultPrimaryCareGapOverrideValidator() -> PrimaryCareGapOverrideValidator {
        return PrimaryCareGapOverrideValidator(
            rules: [
                PrimaryCareGapOverrideTitleLengthRule(maxLength: 32),
                PrimaryCareGapOverrideRequiredTitleRule(message: "primary care gap override needs an entry"),
                PrimaryCareGapOverrideAllowedCodeRule(allowed: ["adaptive", "lenient", "manual"]),
                PrimaryCareGapOverrideCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
