import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness allocation must pass. Check returns its problems, or none.
    protocol WitnessAllocationRule {
        func check(_ item: WitnessAllocation) -> [String]
    }

    final class WitnessAllocationAllowedTitleRule: WitnessAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is inconsistent"]
            }
            return []
        }
    }

    final class WitnessAllocationMinimumRangeRule: WitnessAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessAllocation) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessAllocationRefillsRangeRule: WitnessAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessAllocation) -> [String] {
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

    final class WitnessAllocationRequiredClinicianIDRule: WitnessAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessAllocation) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness allocation.
    final class WitnessAllocationValidator {
        var rules: [any WitnessAllocationRule]

        init(rules: [any WitnessAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessAllocation) -> [String] {
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

        func requireValid(_ item: WitnessAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessAllocation]) -> [String: [String]] {
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

    static func defaultWitnessAllocationValidator() -> WitnessAllocationValidator {
        return WitnessAllocationValidator(
            rules: [
                WitnessAllocationAllowedTitleRule(allowed: []),
                WitnessAllocationMinimumRangeRule(min: 5.9, max: 3632.0),
                WitnessAllocationRefillsRangeRule(min: 64, max: 255),
                WitnessAllocationRequiredClinicianIDRule(message: "witness allocation needs a value"),
            ]
        )
    }
}
