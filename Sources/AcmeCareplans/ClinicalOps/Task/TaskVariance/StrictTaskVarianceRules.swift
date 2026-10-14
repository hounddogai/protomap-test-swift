import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a strict task variance must pass. Check returns its problems, or none.
    protocol StrictTaskVarianceRule {
        func check(_ item: StrictTaskVariance) -> [String]
    }

    final class StrictTaskVarianceExternalRefLengthRule: StrictTaskVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictTaskVariance) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictTaskVarianceCodePrefixRule: StrictTaskVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictTaskVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictTaskVarianceRateRangeRule: StrictTaskVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictTaskVariance) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictTaskVarianceAmountRangeRule: StrictTaskVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictTaskVariance) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictTaskVarianceRequiredNameRule: StrictTaskVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictTaskVariance) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictTaskVarianceChecksumLengthRule: StrictTaskVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictTaskVariance) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict task variance.
    final class StrictTaskVarianceValidator {
        var rules: [any StrictTaskVarianceRule]

        init(rules: [any StrictTaskVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictTaskVariance) -> [String] {
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

        func requireValid(_ item: StrictTaskVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictTaskVariance]) -> [String: [String]] {
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

    static func defaultStrictTaskVarianceValidator() -> StrictTaskVarianceValidator {
        return StrictTaskVarianceValidator(
            rules: [
                StrictTaskVarianceExternalRefLengthRule(maxLength: 64),
                StrictTaskVarianceCodePrefixRule(prefix: "ACM"),
                StrictTaskVarianceRateRangeRule(min: 4.2, max: 3778.1),
                StrictTaskVarianceAmountRangeRule(min: 3.9, max: 2138.3),
                StrictTaskVarianceRequiredNameRule(message: "strict task variance needs an entry"),
                StrictTaskVarianceChecksumLengthRule(maxLength: 120),
            ]
        )
    }
}
