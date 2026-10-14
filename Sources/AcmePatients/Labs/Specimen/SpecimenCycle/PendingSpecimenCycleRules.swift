import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending specimen cycle must pass. Check returns its problems, or none.
    protocol PendingSpecimenCycleRule {
        func check(_ item: PendingSpecimenCycle) -> [String]
    }

    final class PendingSpecimenCycleLabelLengthRule: PendingSpecimenCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSpecimenCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingSpecimenCycleRequiredCountryRule: PendingSpecimenCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSpecimenCycle) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSpecimenCycleExpiresAtRangeRule: PendingSpecimenCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSpecimenCycle) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingSpecimenCycleAllowedCodeRule: PendingSpecimenCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingSpecimenCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class PendingSpecimenCycleRequiredCodeRule: PendingSpecimenCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSpecimenCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSpecimenCycleCostRangeRule: PendingSpecimenCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSpecimenCycle) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending specimen cycle.
    final class PendingSpecimenCycleValidator {
        var rules: [any PendingSpecimenCycleRule]

        init(rules: [any PendingSpecimenCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSpecimenCycle) -> [String] {
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

        func requireValid(_ item: PendingSpecimenCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSpecimenCycle]) -> [String: [String]] {
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

    static func defaultPendingSpecimenCycleValidator() -> PendingSpecimenCycleValidator {
        return PendingSpecimenCycleValidator(
            rules: [
                PendingSpecimenCycleLabelLengthRule(maxLength: 120),
                PendingSpecimenCycleRequiredCountryRule(message: "pending specimen cycle needs this field"),
                PendingSpecimenCycleExpiresAtRangeRule(min: 64, max: 255),
                PendingSpecimenCycleAllowedCodeRule(allowed: ["rolling", "regional"]),
                PendingSpecimenCycleRequiredCodeRule(message: "pending specimen cycle needs a value"),
                PendingSpecimenCycleCostRangeRule(min: 3.2, max: 3633.1),
            ]
        )
    }
}
