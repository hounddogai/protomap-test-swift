import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a legacy modality threshold must pass. Check returns its problems, or none.
    protocol LegacyModalityThresholdRule {
        func check(_ item: LegacyModalityThreshold) -> [String]
    }

    final class LegacyModalityThresholdNameLengthRule: LegacyModalityThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyModalityThreshold) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyModalityThresholdDosageMgRangeRule: LegacyModalityThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyModalityThreshold) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyModalityThresholdCodePrefixRule: LegacyModalityThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyModalityThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyModalityThresholdRequiredCodeRule: LegacyModalityThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyModalityThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyModalityThresholdRequiredNameRule: LegacyModalityThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyModalityThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy modality threshold.
    final class LegacyModalityThresholdValidator {
        var rules: [any LegacyModalityThresholdRule]

        init(rules: [any LegacyModalityThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyModalityThreshold) -> [String] {
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

        func requireValid(_ item: LegacyModalityThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyModalityThreshold]) -> [String: [String]] {
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

    static func defaultLegacyModalityThresholdValidator() -> LegacyModalityThresholdValidator {
        return LegacyModalityThresholdValidator(
            rules: [
                LegacyModalityThresholdNameLengthRule(maxLength: 255),
                LegacyModalityThresholdDosageMgRangeRule(min: 5.7, max: 3922.3),
                LegacyModalityThresholdCodePrefixRule(prefix: "ACM"),
                LegacyModalityThresholdRequiredCodeRule(message: "legacy modality threshold needs this field"),
                LegacyModalityThresholdRequiredNameRule(message: "legacy modality threshold needs a value"),
            ]
        )
    }
}
