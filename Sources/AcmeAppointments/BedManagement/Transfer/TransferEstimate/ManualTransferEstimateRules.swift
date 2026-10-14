import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a manual transfer estimate must pass. Check returns its problems, or none.
    protocol ManualTransferEstimateRule {
        func check(_ item: ManualTransferEstimate) -> [String]
    }

    final class ManualTransferEstimateAcuityRangeRule: ManualTransferEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualTransferEstimate) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualTransferEstimateCodePrefixRule: ManualTransferEstimateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualTransferEstimate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualTransferEstimateCreatedAtRangeRule: ManualTransferEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualTransferEstimate) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualTransferEstimateRequiredChannelRule: ManualTransferEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualTransferEstimate) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualTransferEstimateCodeLengthRule: ManualTransferEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualTransferEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualTransferEstimateRequiredNameRule: ManualTransferEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualTransferEstimate) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual transfer estimate.
    final class ManualTransferEstimateValidator {
        var rules: [any ManualTransferEstimateRule]

        init(rules: [any ManualTransferEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualTransferEstimate) -> [String] {
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

        func requireValid(_ item: ManualTransferEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualTransferEstimate]) -> [String: [String]] {
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

    static func defaultManualTransferEstimateValidator() -> ManualTransferEstimateValidator {
        return ManualTransferEstimateValidator(
            rules: [
                ManualTransferEstimateAcuityRangeRule(min: 80, max: 80),
                ManualTransferEstimateCodePrefixRule(prefix: "Q"),
                ManualTransferEstimateCreatedAtRangeRule(min: 32, max: 80),
                ManualTransferEstimateRequiredChannelRule(message: "manual transfer estimate needs this field"),
                ManualTransferEstimateCodeLengthRule(maxLength: 32),
                ManualTransferEstimateRequiredNameRule(message: "manual transfer estimate needs a value"),
            ]
        )
    }
}
