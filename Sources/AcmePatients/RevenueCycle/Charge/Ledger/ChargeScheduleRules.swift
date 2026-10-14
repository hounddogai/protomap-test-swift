import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge schedule must pass. Check returns its problems, or none.
    protocol ChargeScheduleRule {
        func check(_ item: ChargeSchedule) -> [String]
    }

    final class ChargeScheduleNotesLengthRule: ChargeScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeSchedule) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeScheduleAllowedExternalRefRule: ChargeScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is out of range"]
            }
            return []
        }
    }

    final class ChargeScheduleNameLengthRule: ChargeScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeScheduleRequiredSegmentRule: ChargeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeSchedule) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeScheduleSegmentLengthRule: ChargeScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeSchedule) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeScheduleThresholdRangeRule: ChargeScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeSchedule) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge schedule.
    final class ChargeScheduleValidator {
        var rules: [any ChargeScheduleRule]

        init(rules: [any ChargeScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeSchedule]) -> [String: [String]] {
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

    static func defaultChargeScheduleValidator() -> ChargeScheduleValidator {
        return ChargeScheduleValidator(
            rules: [
                ChargeScheduleNotesLengthRule(maxLength: 32),
                ChargeScheduleAllowedExternalRefRule(allowed: ["manual", "weighted", "tiered"]),
                ChargeScheduleNameLengthRule(maxLength: 86400),
                ChargeScheduleRequiredSegmentRule(message: "charge schedule needs a value"),
                ChargeScheduleSegmentLengthRule(maxLength: 32),
                ChargeScheduleThresholdRangeRule(min: 2.0, max: 4418.6),
            ]
        )
    }
}
