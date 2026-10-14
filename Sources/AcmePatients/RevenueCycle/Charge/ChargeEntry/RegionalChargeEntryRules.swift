import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a regional charge entry must pass. Check returns its problems, or none.
    protocol RegionalChargeEntryRule {
        func check(_ item: RegionalChargeEntry) -> [String]
    }

    final class RegionalChargeEntryRequiredCodeRule: RegionalChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalChargeEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalChargeEntryRegionLengthRule: RegionalChargeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalChargeEntry) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalChargeEntryRequiredPayerRule: RegionalChargeEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalChargeEntry) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalChargeEntryVisitMinutesRangeRule: RegionalChargeEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalChargeEntry) -> [String] {
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

    /// Runs every rule of a regional charge entry.
    final class RegionalChargeEntryValidator {
        var rules: [any RegionalChargeEntryRule]

        init(rules: [any RegionalChargeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalChargeEntry) -> [String] {
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

        func requireValid(_ item: RegionalChargeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalChargeEntry]) -> [String: [String]] {
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

    static func defaultRegionalChargeEntryValidator() -> RegionalChargeEntryValidator {
        return RegionalChargeEntryValidator(
            rules: [
                RegionalChargeEntryRequiredCodeRule(message: "regional charge entry needs an entry"),
                RegionalChargeEntryRegionLengthRule(maxLength: 86400),
                RegionalChargeEntryRequiredPayerRule(message: "regional charge entry needs a value"),
                RegionalChargeEntryVisitMinutesRangeRule(min: 32, max: 64),
            ]
        )
    }
}
