import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a read adjustment must pass. Check returns its problems, or none.
    protocol ReadAdjustmentRule {
        func check(_ item: ReadAdjustment) -> [String]
    }

    final class ReadAdjustmentCodePrefixRule: ReadAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReadAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ReadAdjustmentAllowedNameRule: ReadAdjustmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReadAdjustment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is not allowed"]
            }
            return []
        }
    }

    final class ReadAdjustmentMinimumRangeRule: ReadAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadAdjustment) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReadAdjustmentRequiredTitleRule: ReadAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReadAdjustment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReadAdjustmentRefillsRangeRule: ReadAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReadAdjustment) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReadAdjustmentNameLengthRule: ReadAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReadAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a read adjustment.
    final class ReadAdjustmentValidator {
        var rules: [any ReadAdjustmentRule]

        init(rules: [any ReadAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ReadAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReadAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReadAdjustment]) -> [String: [String]] {
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

    static func defaultReadAdjustmentValidator() -> ReadAdjustmentValidator {
        return ReadAdjustmentValidator(
            rules: [
                ReadAdjustmentCodePrefixRule(prefix: "Q"),
                ReadAdjustmentAllowedNameRule(allowed: ["capped", "manual"]),
                ReadAdjustmentMinimumRangeRule(min: 1.4, max: 1505.7),
                ReadAdjustmentRequiredTitleRule(message: "read adjustment needs an entry"),
                ReadAdjustmentRefillsRangeRule(min: 16, max: 64),
                ReadAdjustmentNameLengthRule(maxLength: 3600),
            ]
        )
    }
}
