import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a global float pool adjustment must pass. Check returns its problems, or none.
    protocol GlobalFloatPoolAdjustmentRule {
        func check(_ item: GlobalFloatPoolAdjustment) -> [String]
    }

    final class GlobalFloatPoolAdjustmentRequiredOwnerIDRule: GlobalFloatPoolAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFloatPoolAdjustment) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFloatPoolAdjustmentRequiredCurrencyRule: GlobalFloatPoolAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFloatPoolAdjustment) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFloatPoolAdjustmentLabelLengthRule: GlobalFloatPoolAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFloatPoolAdjustment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global float pool adjustment.
    final class GlobalFloatPoolAdjustmentValidator {
        var rules: [any GlobalFloatPoolAdjustmentRule]

        init(rules: [any GlobalFloatPoolAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFloatPoolAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalFloatPoolAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFloatPoolAdjustment]) -> [String: [String]] {
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

    static func defaultGlobalFloatPoolAdjustmentValidator() -> GlobalFloatPoolAdjustmentValidator {
        return GlobalFloatPoolAdjustmentValidator(
            rules: [
                GlobalFloatPoolAdjustmentRequiredOwnerIDRule(message: "global float pool adjustment needs an entry"),
                GlobalFloatPoolAdjustmentRequiredCurrencyRule(message: "global float pool adjustment needs an entry"),
                GlobalFloatPoolAdjustmentLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
