import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary inventory agreement must pass. Check returns its problems, or none.
    protocol PrimaryInventoryAgreementRule {
        func check(_ item: PrimaryInventoryAgreement) -> [String]
    }

    final class PrimaryInventoryAgreementCodePrefixRule: PrimaryInventoryAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryInventoryAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryInventoryAgreementThresholdRangeRule: PrimaryInventoryAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryInventoryAgreement) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryInventoryAgreementRequiredBedRule: PrimaryInventoryAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInventoryAgreement) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInventoryAgreementRequiredTitleRule: PrimaryInventoryAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryInventoryAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryInventoryAgreementBedLengthRule: PrimaryInventoryAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryInventoryAgreement) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary inventory agreement.
    final class PrimaryInventoryAgreementValidator {
        var rules: [any PrimaryInventoryAgreementRule]

        init(rules: [any PrimaryInventoryAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryInventoryAgreement) -> [String] {
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

        func requireValid(_ item: PrimaryInventoryAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryInventoryAgreement]) -> [String: [String]] {
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

    static func defaultPrimaryInventoryAgreementValidator() -> PrimaryInventoryAgreementValidator {
        return PrimaryInventoryAgreementValidator(
            rules: [
                PrimaryInventoryAgreementCodePrefixRule(prefix: "X"),
                PrimaryInventoryAgreementThresholdRangeRule(min: 0.1, max: 2953.9),
                PrimaryInventoryAgreementRequiredBedRule(message: "primary inventory agreement needs this field"),
                PrimaryInventoryAgreementRequiredTitleRule(message: "primary inventory agreement needs this field"),
                PrimaryInventoryAgreementBedLengthRule(maxLength: 16),
            ]
        )
    }
}
