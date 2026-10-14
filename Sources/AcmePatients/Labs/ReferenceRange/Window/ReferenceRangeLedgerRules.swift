import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range ledger must pass. Check returns its problems, or none.
    protocol ReferenceRangeLedgerRule {
        func check(_ item: ReferenceRangeLedger) -> [String]
    }

    final class ReferenceRangeLedgerRegionLengthRule: ReferenceRangeLedgerRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeLedger) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeLedgerAllowedNameRule: ReferenceRangeLedgerRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeLedger) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class ReferenceRangeLedgerWeightRangeRule: ReferenceRangeLedgerRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeLedger) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeLedgerRequiredNotesRule: ReferenceRangeLedgerRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeLedger) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeLedgerRevisionRangeRule: ReferenceRangeLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeLedger) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ReferenceRangeLedgerUpdatedAtRangeRule: ReferenceRangeLedgerRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeLedger) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range ledger.
    final class ReferenceRangeLedgerValidator {
        var rules: [any ReferenceRangeLedgerRule]

        init(rules: [any ReferenceRangeLedgerRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeLedger) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeLedger) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeLedger]) -> [String: [String]] {
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

    static func defaultReferenceRangeLedgerValidator() -> ReferenceRangeLedgerValidator {
        return ReferenceRangeLedgerValidator(
            rules: [
                ReferenceRangeLedgerRegionLengthRule(maxLength: 1000),
                ReferenceRangeLedgerAllowedNameRule(allowed: ["lenient", "lenient"]),
                ReferenceRangeLedgerWeightRangeRule(min: 8.6, max: 2734.4),
                ReferenceRangeLedgerRequiredNotesRule(message: "reference range ledger needs this field"),
                ReferenceRangeLedgerRevisionRangeRule(min: 64, max: 1000),
                ReferenceRangeLedgerUpdatedAtRangeRule(min: 80, max: 120),
            ]
        )
    }
}
