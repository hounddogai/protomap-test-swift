import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a dispense summary must pass. Check returns its problems, or none.
    protocol DispenseSummaryRule {
        func check(_ item: DispenseSummary) -> [String]
    }

    final class DispenseSummaryRequiredRegionRule: DispenseSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DispenseSummary) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DispenseSummaryCodeLengthRule: DispenseSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseSummaryVisitMinutesRangeRule: DispenseSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseSummary) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DispenseSummaryRatioRangeRule: DispenseSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DispenseSummary) -> [String] {
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

    final class DispenseSummaryTitleLengthRule: DispenseSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseSummary) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DispenseSummaryOwnerIDLengthRule: DispenseSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DispenseSummary) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a dispense summary.
    final class DispenseSummaryValidator {
        var rules: [any DispenseSummaryRule]

        init(rules: [any DispenseSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: DispenseSummary) -> [String] {
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

        func requireValid(_ item: DispenseSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DispenseSummary]) -> [String: [String]] {
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

    static func defaultDispenseSummaryValidator() -> DispenseSummaryValidator {
        return DispenseSummaryValidator(
            rules: [
                DispenseSummaryRequiredRegionRule(message: "dispense summary needs an entry"),
                DispenseSummaryCodeLengthRule(maxLength: 32),
                DispenseSummaryVisitMinutesRangeRule(min: 64, max: 120),
                DispenseSummaryRatioRangeRule(min: 0.5, max: 1272.9),
                DispenseSummaryTitleLengthRule(maxLength: 80),
                DispenseSummaryOwnerIDLengthRule(maxLength: 3600),
            ]
        )
    }
}
