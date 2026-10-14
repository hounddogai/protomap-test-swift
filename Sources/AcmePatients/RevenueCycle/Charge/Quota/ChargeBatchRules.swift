import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge batch must pass. Check returns its problems, or none.
    protocol ChargeBatchRule {
        func check(_ item: ChargeBatch) -> [String]
    }

    final class ChargeBatchAllowedSegmentRule: ChargeBatchRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeBatch) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is above maximum"]
            }
            return []
        }
    }

    final class ChargeBatchRequiredCodeRule: ChargeBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeBatch) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeBatchCodeLengthRule: ChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeBatch) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeBatchSequenceRangeRule: ChargeBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeBatch) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeBatchCodePrefixRule: ChargeBatchRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ChargeBatch) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ChargeBatchSegmentLengthRule: ChargeBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeBatch) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge batch.
    final class ChargeBatchValidator {
        var rules: [any ChargeBatchRule]

        init(rules: [any ChargeBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeBatch]) -> [String: [String]] {
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

    static func defaultChargeBatchValidator() -> ChargeBatchValidator {
        return ChargeBatchValidator(
            rules: [
                ChargeBatchAllowedSegmentRule(allowed: ["primary"]),
                ChargeBatchRequiredCodeRule(message: "charge batch needs a value"),
                ChargeBatchCodeLengthRule(maxLength: 1000),
                ChargeBatchSequenceRangeRule(min: 32, max: 255),
                ChargeBatchCodePrefixRule(prefix: "ACM"),
                ChargeBatchSegmentLengthRule(maxLength: 64),
            ]
        )
    }
}
