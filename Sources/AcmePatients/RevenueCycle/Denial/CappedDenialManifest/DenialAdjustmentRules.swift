import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial adjustment must pass. Check returns its problems, or none.
    protocol DenialAdjustmentRule {
        func check(_ item: DenialAdjustment) -> [String]
    }

    final class DenialAdjustmentNameLengthRule: DenialAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialAdjustment) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialAdjustmentRequiredCodeRule: DenialAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialAdjustment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialAdjustmentRequiredCategoryRule: DenialAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialAdjustment) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a denial adjustment.
    final class DenialAdjustmentValidator {
        var rules: [any DenialAdjustmentRule]

        init(rules: [any DenialAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialAdjustment) -> [String] {
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

        func requireValid(_ item: DenialAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialAdjustment]) -> [String: [String]] {
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

    static func defaultDenialAdjustmentValidator() -> DenialAdjustmentValidator {
        return DenialAdjustmentValidator(
            rules: [
                DenialAdjustmentNameLengthRule(maxLength: 120),
                DenialAdjustmentRequiredCodeRule(message: "denial adjustment needs an entry"),
                DenialAdjustmentRequiredCategoryRule(message: "denial adjustment needs this field"),
            ]
        )
    }
}
