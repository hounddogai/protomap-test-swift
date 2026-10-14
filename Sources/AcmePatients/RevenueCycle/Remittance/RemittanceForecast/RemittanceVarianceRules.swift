import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance variance must pass. Check returns its problems, or none.
    protocol RemittanceVarianceRule {
        func check(_ item: RemittanceVariance) -> [String]
    }

    final class RemittanceVarianceCodePrefixRule: RemittanceVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RemittanceVarianceRequiredNameRule: RemittanceVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceVariance) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceVarianceCodeLengthRule: RemittanceVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceVarianceRequiredOwnerIDRule: RemittanceVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceVariance) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceVarianceQuantityRangeRule: RemittanceVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceVariance) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RemittanceVarianceGraceDaysRangeRule: RemittanceVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RemittanceVariance) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a remittance variance.
    final class RemittanceVarianceValidator {
        var rules: [any RemittanceVarianceRule]

        init(rules: [any RemittanceVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceVariance]) -> [String: [String]] {
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

    static func defaultRemittanceVarianceValidator() -> RemittanceVarianceValidator {
        return RemittanceVarianceValidator(
            rules: [
                RemittanceVarianceCodePrefixRule(prefix: "OPS"),
                RemittanceVarianceRequiredNameRule(message: "remittance variance needs this field"),
                RemittanceVarianceCodeLengthRule(maxLength: 86400),
                RemittanceVarianceRequiredOwnerIDRule(message: "remittance variance needs a value"),
                RemittanceVarianceQuantityRangeRule(min: 120, max: 3600),
                RemittanceVarianceGraceDaysRangeRule(min: 16, max: 16),
            ]
        )
    }
}
