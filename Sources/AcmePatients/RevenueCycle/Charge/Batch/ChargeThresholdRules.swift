import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge threshold must pass. Check returns its problems, or none.
    protocol ChargeThresholdRule {
        func check(_ item: ChargeThreshold) -> [String]
    }

    final class ChargeThresholdTimezoneLengthRule: ChargeThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeThreshold) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeThresholdCodePrefixRule: ChargeThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeThresholdEncounterIDLengthRule: ChargeThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeThreshold) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeThresholdThresholdRangeRule: ChargeThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeThreshold) -> [String] {
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

    final class ChargeThresholdCodeLengthRule: ChargeThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge threshold.
    final class ChargeThresholdValidator {
        var rules: [any ChargeThresholdRule]

        init(rules: [any ChargeThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeThreshold]) -> [String: [String]] {
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

    static func defaultChargeThresholdValidator() -> ChargeThresholdValidator {
        return ChargeThresholdValidator(
            rules: [
                ChargeThresholdTimezoneLengthRule(maxLength: 86400),
                ChargeThresholdCodePrefixRule(prefix: "ACM"),
                ChargeThresholdEncounterIDLengthRule(maxLength: 64),
                ChargeThresholdThresholdRangeRule(min: 7.1, max: 1613.5),
                ChargeThresholdCodeLengthRule(maxLength: 3600),
            ]
        )
    }
}
