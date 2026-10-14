import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result adjustment must pass. Check returns its problems, or none.
    protocol ResultAdjustmentRule {
        func check(_ item: ResultAdjustment) -> [String]
    }

    final class ResultAdjustmentQuantityRangeRule: ResultAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultAdjustment) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultAdjustmentNameLengthRule: ResultAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultAdjustmentCodePrefixRule: ResultAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultAdjustmentRequiredNameRule: ResultAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultAdjustment) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultAdjustmentLimitRangeRule: ResultAdjustmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultAdjustment) -> [String] {
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

    /// Runs every rule of a result adjustment.
    final class ResultAdjustmentValidator {
        var rules: [any ResultAdjustmentRule]

        init(rules: [any ResultAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultAdjustment) -> [String] {
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

        func requireValid(_ item: ResultAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultAdjustment]) -> [String: [String]] {
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

    static func defaultResultAdjustmentValidator() -> ResultAdjustmentValidator {
        return ResultAdjustmentValidator(
            rules: [
                ResultAdjustmentQuantityRangeRule(min: 64, max: 3600),
                ResultAdjustmentNameLengthRule(maxLength: 16),
                ResultAdjustmentCodePrefixRule(prefix: "OPS"),
                ResultAdjustmentRequiredNameRule(message: "result adjustment needs a value"),
                ResultAdjustmentLimitRangeRule(min: 64, max: 120),
            ]
        )
    }
}
