import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan override must pass. Check returns its problems, or none.
    protocol AcuityPlanOverrideRule {
        func check(_ item: AcuityPlanOverride) -> [String]
    }

    final class AcuityPlanOverrideCodeLengthRule: AcuityPlanOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanOverridePayerLengthRule: AcuityPlanOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanOverride) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanOverrideCodePrefixRule: AcuityPlanOverrideRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AcuityPlanOverride) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class AcuityPlanOverrideRequiredPayerRule: AcuityPlanOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanOverride) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanOverrideAllowedChecksumRule: AcuityPlanOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AcuityPlanOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is not allowed"]
            }
            return []
        }
    }

    final class AcuityPlanOverrideRequiredTitleRule: AcuityPlanOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan override.
    final class AcuityPlanOverrideValidator {
        var rules: [any AcuityPlanOverrideRule]

        init(rules: [any AcuityPlanOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanOverride) -> [String] {
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

        func requireValid(_ item: AcuityPlanOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanOverride]) -> [String: [String]] {
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

    static func defaultAcuityPlanOverrideValidator() -> AcuityPlanOverrideValidator {
        return AcuityPlanOverrideValidator(
            rules: [
                AcuityPlanOverrideCodeLengthRule(maxLength: 80),
                AcuityPlanOverridePayerLengthRule(maxLength: 120),
                AcuityPlanOverrideCodePrefixRule(prefix: "REF"),
                AcuityPlanOverrideRequiredPayerRule(message: "acuity plan override needs a value"),
                AcuityPlanOverrideAllowedChecksumRule(allowed: ["pending", "weighted"]),
                AcuityPlanOverrideRequiredTitleRule(message: "acuity plan override needs this field"),
            ]
        )
    }
}
