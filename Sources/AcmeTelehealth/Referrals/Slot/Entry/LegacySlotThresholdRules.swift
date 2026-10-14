import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy slot threshold must pass. Check returns its problems, or none.
    protocol LegacySlotThresholdRule {
        func check(_ item: LegacySlotThreshold) -> [String]
    }

    final class LegacySlotThresholdRequiredReviewerRule: LegacySlotThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySlotThreshold) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacySlotThresholdCodeLengthRule: LegacySlotThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySlotThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySlotThresholdCodePrefixRule: LegacySlotThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacySlotThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacySlotThresholdRequiredCodeRule: LegacySlotThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySlotThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy slot threshold.
    final class LegacySlotThresholdValidator {
        var rules: [any LegacySlotThresholdRule]

        init(rules: [any LegacySlotThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySlotThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacySlotThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySlotThreshold]) -> [String: [String]] {
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

    static func defaultLegacySlotThresholdValidator() -> LegacySlotThresholdValidator {
        return LegacySlotThresholdValidator(
            rules: [
                LegacySlotThresholdRequiredReviewerRule(message: "legacy slot threshold needs this field"),
                LegacySlotThresholdCodeLengthRule(maxLength: 255),
                LegacySlotThresholdCodePrefixRule(prefix: "OPS"),
                LegacySlotThresholdRequiredCodeRule(message: "legacy slot threshold needs an entry"),
            ]
        )
    }
}
