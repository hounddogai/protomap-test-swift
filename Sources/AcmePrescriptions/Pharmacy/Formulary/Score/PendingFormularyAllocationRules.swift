import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending formulary allocation must pass. Check returns its problems, or none.
    protocol PendingFormularyAllocationRule {
        func check(_ item: PendingFormularyAllocation) -> [String]
    }

    final class PendingFormularyAllocationRequiredCodeRule: PendingFormularyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFormularyAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFormularyAllocationRequiredClinicianIDRule: PendingFormularyAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingFormularyAllocation) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingFormularyAllocationMarginRangeRule: PendingFormularyAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingFormularyAllocation) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending formulary allocation.
    final class PendingFormularyAllocationValidator {
        var rules: [any PendingFormularyAllocationRule]

        init(rules: [any PendingFormularyAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingFormularyAllocation) -> [String] {
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

        func requireValid(_ item: PendingFormularyAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingFormularyAllocation]) -> [String: [String]] {
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

    static func defaultPendingFormularyAllocationValidator() -> PendingFormularyAllocationValidator {
        return PendingFormularyAllocationValidator(
            rules: [
                PendingFormularyAllocationRequiredCodeRule(message: "pending formulary allocation needs an entry"),
                PendingFormularyAllocationRequiredClinicianIDRule(
                    message: "pending formulary allocation needs an entry"
                ),
                PendingFormularyAllocationMarginRangeRule(min: 1.7, max: 1785.6),
            ]
        )
    }
}
