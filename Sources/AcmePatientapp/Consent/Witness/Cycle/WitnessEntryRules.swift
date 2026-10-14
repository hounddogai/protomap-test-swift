import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness entry must pass. Check returns its problems, or none.
    protocol WitnessEntryRule {
        func check(_ item: WitnessEntry) -> [String]
    }

    final class WitnessEntryVisitMinutesRangeRule: WitnessEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessEntry) -> [String] {
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

    final class WitnessEntryFloorValueRangeRule: WitnessEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessEntry) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessEntryRefillsRangeRule: WitnessEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessEntry) -> [String] {
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

    final class WitnessEntryCodePrefixRule: WitnessEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness entry.
    final class WitnessEntryValidator {
        var rules: [any WitnessEntryRule]

        init(rules: [any WitnessEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessEntry]) -> [String: [String]] {
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

    static func defaultWitnessEntryValidator() -> WitnessEntryValidator {
        return WitnessEntryValidator(
            rules: [
                WitnessEntryVisitMinutesRangeRule(min: 80, max: 3600),
                WitnessEntryFloorValueRangeRule(min: 3.2, max: 438.6),
                WitnessEntryRefillsRangeRule(min: 1000, max: 1000),
                WitnessEntryCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
