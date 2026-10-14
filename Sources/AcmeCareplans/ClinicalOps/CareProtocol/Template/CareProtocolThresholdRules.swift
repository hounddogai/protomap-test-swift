import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol threshold must pass. Check returns its problems, or none.
    protocol CareProtocolThresholdRule {
        func check(_ item: CareProtocolThreshold) -> [String]
    }

    final class CareProtocolThresholdRateRangeRule: CareProtocolThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolThresholdRequiredTitleRule: CareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolThresholdAmountRangeRule: CareProtocolThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolThresholdCodePrefixRule: CareProtocolThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolThresholdNotesLengthRule: CareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolThreshold) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol threshold.
    final class CareProtocolThresholdValidator {
        var rules: [any CareProtocolThresholdRule]

        init(rules: [any CareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolThreshold) -> [String] {
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

        func requireValid(_ item: CareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultCareProtocolThresholdValidator() -> CareProtocolThresholdValidator {
        return CareProtocolThresholdValidator(
            rules: [
                CareProtocolThresholdRateRangeRule(min: 0.7, max: 4728.4),
                CareProtocolThresholdRequiredTitleRule(message: "care protocol threshold needs an entry"),
                CareProtocolThresholdAmountRangeRule(min: 8.2, max: 4580.8),
                CareProtocolThresholdCodePrefixRule(prefix: "REF"),
                CareProtocolThresholdNotesLengthRule(maxLength: 80),
            ]
        )
    }
}
