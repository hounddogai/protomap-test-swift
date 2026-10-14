import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge segment must pass. Check returns its problems, or none.
    protocol ChargeSegmentRule {
        func check(_ item: ChargeSegment) -> [String]
    }

    final class ChargeSegmentLimitRangeRule: ChargeSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeSegment) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeSegmentRequiredCodeRule: ChargeSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeSegmentCodePrefixRule: ChargeSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge segment.
    final class ChargeSegmentValidator {
        var rules: [any ChargeSegmentRule]

        init(rules: [any ChargeSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeSegment]) -> [String: [String]] {
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

    static func defaultChargeSegmentValidator() -> ChargeSegmentValidator {
        return ChargeSegmentValidator(
            rules: [
                ChargeSegmentLimitRangeRule(min: 16, max: 32),
                ChargeSegmentRequiredCodeRule(message: "charge segment needs a value"),
                ChargeSegmentCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
