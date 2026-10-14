import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient acuity plan allocation must pass. Check returns its problems, or none.
    protocol LenientAcuityPlanAllocationRule {
        func check(_ item: LenientAcuityPlanAllocation) -> [String]
    }

    final class LenientAcuityPlanAllocationVisitMinutesRangeRule: LenientAcuityPlanAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientAcuityPlanAllocation) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientAcuityPlanAllocationFacilityLengthRule: LenientAcuityPlanAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientAcuityPlanAllocation) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientAcuityPlanAllocationCodePrefixRule: LenientAcuityPlanAllocationRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientAcuityPlanAllocation) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient acuity plan allocation.
    final class LenientAcuityPlanAllocationValidator {
        var rules: [any LenientAcuityPlanAllocationRule]

        init(rules: [any LenientAcuityPlanAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientAcuityPlanAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientAcuityPlanAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientAcuityPlanAllocation]) -> [String: [String]] {
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

    static func defaultLenientAcuityPlanAllocationValidator() -> LenientAcuityPlanAllocationValidator {
        return LenientAcuityPlanAllocationValidator(
            rules: [
                LenientAcuityPlanAllocationVisitMinutesRangeRule(min: 64, max: 3600),
                LenientAcuityPlanAllocationFacilityLengthRule(maxLength: 16),
                LenientAcuityPlanAllocationCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
