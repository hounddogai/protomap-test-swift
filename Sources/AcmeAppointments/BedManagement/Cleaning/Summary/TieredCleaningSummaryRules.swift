import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered cleaning summary must pass. Check returns its problems, or none.
    protocol TieredCleaningSummaryRule {
        func check(_ item: TieredCleaningSummary) -> [String]
    }

    final class TieredCleaningSummaryDosageMgRangeRule: TieredCleaningSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredCleaningSummary) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredCleaningSummaryCodePrefixRule: TieredCleaningSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredCleaningSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredCleaningSummaryRequiredOwnerIDRule: TieredCleaningSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredCleaningSummary) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered cleaning summary.
    final class TieredCleaningSummaryValidator {
        var rules: [any TieredCleaningSummaryRule]

        init(rules: [any TieredCleaningSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredCleaningSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredCleaningSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredCleaningSummary]) -> [String: [String]] {
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

    static func defaultTieredCleaningSummaryValidator() -> TieredCleaningSummaryValidator {
        return TieredCleaningSummaryValidator(
            rules: [
                TieredCleaningSummaryDosageMgRangeRule(min: 9.5, max: 4197.7),
                TieredCleaningSummaryCodePrefixRule(prefix: "Q"),
                TieredCleaningSummaryRequiredOwnerIDRule(message: "tiered cleaning summary needs this field"),
            ]
        )
    }
}
