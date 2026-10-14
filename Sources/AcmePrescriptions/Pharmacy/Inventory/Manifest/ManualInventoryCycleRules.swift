import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual inventory cycle must pass. Check returns its problems, or none.
    protocol ManualInventoryCycleRule {
        func check(_ item: ManualInventoryCycle) -> [String]
    }

    final class ManualInventoryCycleRegionLengthRule: ManualInventoryCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventoryCycle) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualInventoryCycleCodeLengthRule: ManualInventoryCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualInventoryCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualInventoryCycleRequiredCodeRule: ManualInventoryCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventoryCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualInventoryCycleDosageMgRangeRule: ManualInventoryCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualInventoryCycle) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual inventory cycle.
    final class ManualInventoryCycleValidator {
        var rules: [any ManualInventoryCycleRule]

        init(rules: [any ManualInventoryCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualInventoryCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualInventoryCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualInventoryCycle]) -> [String: [String]] {
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

    static func defaultManualInventoryCycleValidator() -> ManualInventoryCycleValidator {
        return ManualInventoryCycleValidator(
            rules: [
                ManualInventoryCycleRegionLengthRule(maxLength: 3600),
                ManualInventoryCycleCodeLengthRule(maxLength: 80),
                ManualInventoryCycleRequiredCodeRule(message: "manual inventory cycle needs a value"),
                ManualInventoryCycleDosageMgRangeRule(min: 3.3, max: 1711.5),
            ]
        )
    }
}
