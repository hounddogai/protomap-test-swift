import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped order set rollup must pass. Check returns its problems, or none.
    protocol CappedOrderSetRollupRule {
        func check(_ item: CappedOrderSetRollup) -> [String]
    }

    final class CappedOrderSetRollupCodePrefixRule: CappedOrderSetRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedOrderSetRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedOrderSetRollupCodeLengthRule: CappedOrderSetRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOrderSetRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedOrderSetRollupRequiredFacilityRule: CappedOrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedOrderSetRollup) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedOrderSetRollupRequiredTimezoneRule: CappedOrderSetRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedOrderSetRollup) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedOrderSetRollupMinimumRangeRule: CappedOrderSetRollupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedOrderSetRollup) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedOrderSetRollupLabelLengthRule: CappedOrderSetRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedOrderSetRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped order set rollup.
    final class CappedOrderSetRollupValidator {
        var rules: [any CappedOrderSetRollupRule]

        init(rules: [any CappedOrderSetRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedOrderSetRollup) -> [String] {
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

        func requireValid(_ item: CappedOrderSetRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedOrderSetRollup]) -> [String: [String]] {
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

    static func defaultCappedOrderSetRollupValidator() -> CappedOrderSetRollupValidator {
        return CappedOrderSetRollupValidator(
            rules: [
                CappedOrderSetRollupCodePrefixRule(prefix: "X"),
                CappedOrderSetRollupCodeLengthRule(maxLength: 80),
                CappedOrderSetRollupRequiredFacilityRule(message: "capped order set rollup needs an entry"),
                CappedOrderSetRollupRequiredTimezoneRule(message: "capped order set rollup needs an entry"),
                CappedOrderSetRollupMinimumRangeRule(min: 2.2, max: 1360.3),
                CappedOrderSetRollupLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
