import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled reference range record must pass. Check returns its problems, or none.
    protocol ScheduledReferenceRangeRecordRule {
        func check(_ item: ScheduledReferenceRangeRecord) -> [String]
    }

    final class ScheduledReferenceRangeRecordRateRangeRule: ScheduledReferenceRangeRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferenceRangeRecord) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeRecordRequiredRegionRule: ScheduledReferenceRangeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledReferenceRangeRecord) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledReferenceRangeRecordWeightRangeRule: ScheduledReferenceRangeRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledReferenceRangeRecord) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled reference range record.
    final class ScheduledReferenceRangeRecordValidator {
        var rules: [any ScheduledReferenceRangeRecordRule]

        init(rules: [any ScheduledReferenceRangeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledReferenceRangeRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledReferenceRangeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledReferenceRangeRecord]) -> [String: [String]] {
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

    static func defaultScheduledReferenceRangeRecordValidator() -> ScheduledReferenceRangeRecordValidator {
        return ScheduledReferenceRangeRecordValidator(
            rules: [
                ScheduledReferenceRangeRecordRateRangeRule(min: 5.3, max: 4017.7),
                ScheduledReferenceRangeRecordRequiredRegionRule(
                    message: "scheduled reference range record needs a value"
                ),
                ScheduledReferenceRangeRecordWeightRangeRule(min: 8.6, max: 115.1),
            ]
        )
    }
}
