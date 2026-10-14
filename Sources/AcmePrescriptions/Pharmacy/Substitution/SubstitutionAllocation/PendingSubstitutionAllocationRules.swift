import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a pending substitution allocation must pass. Check returns its problems, or none.
    protocol PendingSubstitutionAllocationRule {
        func check(_ item: PendingSubstitutionAllocation) -> [String]
    }

    final class PendingSubstitutionAllocationWindowDaysRangeRule: PendingSubstitutionAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSubstitutionAllocation) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingSubstitutionAllocationAllowedCodeRule: PendingSubstitutionAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingSubstitutionAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class PendingSubstitutionAllocationRefillsRangeRule: PendingSubstitutionAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSubstitutionAllocation) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingSubstitutionAllocationTitleLengthRule: PendingSubstitutionAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingSubstitutionAllocation) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending substitution allocation.
    final class PendingSubstitutionAllocationValidator {
        var rules: [any PendingSubstitutionAllocationRule]

        init(rules: [any PendingSubstitutionAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSubstitutionAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingSubstitutionAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSubstitutionAllocation]) -> [String: [String]] {
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

    static func defaultPendingSubstitutionAllocationValidator() -> PendingSubstitutionAllocationValidator {
        return PendingSubstitutionAllocationValidator(
            rules: [
                PendingSubstitutionAllocationWindowDaysRangeRule(min: 32, max: 64),
                PendingSubstitutionAllocationAllowedCodeRule(allowed: ["weighted", "manual", "tiered"]),
                PendingSubstitutionAllocationRefillsRangeRule(min: 120, max: 255),
                PendingSubstitutionAllocationTitleLengthRule(maxLength: 120),
            ]
        )
    }
}
