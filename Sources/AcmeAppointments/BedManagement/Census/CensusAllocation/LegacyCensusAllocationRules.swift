import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy census allocation must pass. Check returns its problems, or none.
    protocol LegacyCensusAllocationRule {
        func check(_ item: LegacyCensusAllocation) -> [String]
    }

    final class LegacyCensusAllocationAllowedChecksumRule: LegacyCensusAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyCensusAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is blocked"]
            }
            return []
        }
    }

    final class LegacyCensusAllocationThresholdRangeRule: LegacyCensusAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCensusAllocation) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCensusAllocationRequiredChecksumRule: LegacyCensusAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCensusAllocation) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy census allocation.
    final class LegacyCensusAllocationValidator {
        var rules: [any LegacyCensusAllocationRule]

        init(rules: [any LegacyCensusAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCensusAllocation) -> [String] {
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

        func requireValid(_ item: LegacyCensusAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCensusAllocation]) -> [String: [String]] {
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

    static func defaultLegacyCensusAllocationValidator() -> LegacyCensusAllocationValidator {
        return LegacyCensusAllocationValidator(
            rules: [
                LegacyCensusAllocationAllowedChecksumRule(allowed: ["manual"]),
                LegacyCensusAllocationThresholdRangeRule(min: 1.9, max: 1653.7),
                LegacyCensusAllocationRequiredChecksumRule(message: "legacy census allocation needs a value"),
            ]
        )
    }
}
