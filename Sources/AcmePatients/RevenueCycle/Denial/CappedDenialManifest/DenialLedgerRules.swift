import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial ledger must pass. Check returns its problems, or none.
    protocol DenialLedgerRule {
        func check(_ item: DenialLedger) -> [String]
    }

    final class DenialLedgerRatioRangeRule: DenialLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialLedger) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DenialLedgerAllowedNameRule: DenialLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is blocked"]
            }
            return []
        }
    }

    final class DenialLedgerRegionLengthRule: DenialLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialLedger) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialLedgerPriorityRangeRule: DenialLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DenialLedger) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial ledger.
    final class DenialLedgerValidator {
        var rules: [any DenialLedgerRule]

        init(rules: [any DenialLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialLedger) -> [String] {
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

        func requireValid(_ item: DenialLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialLedger]) -> [String: [String]] {
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

    static func defaultDenialLedgerValidator() -> DenialLedgerValidator {
        return DenialLedgerValidator(
            rules: [
                DenialLedgerRatioRangeRule(min: 2.5, max: 1955.8),
                DenialLedgerAllowedNameRule(allowed: ["weighted", "rolling", "batched"]),
                DenialLedgerRegionLengthRule(maxLength: 3600),
                DenialLedgerPriorityRangeRule(min: 255, max: 1000),
            ]
        )
    }
}
