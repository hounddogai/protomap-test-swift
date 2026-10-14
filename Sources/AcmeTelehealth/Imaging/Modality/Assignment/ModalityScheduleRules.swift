import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality schedule must pass. Check returns its problems, or none.
    protocol ModalityScheduleRule {
        func check(_ item: ModalitySchedule) -> [String]
    }

    final class ModalityScheduleCopayRangeRule: ModalityScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalitySchedule) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityScheduleRequiredChecksumRule: ModalityScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalitySchedule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityScheduleAcuityRangeRule: ModalityScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalitySchedule) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ModalityScheduleRequiredCodeRule: ModalityScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalitySchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityScheduleScoreRangeRule: ModalityScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ModalitySchedule) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a modality schedule.
    final class ModalityScheduleValidator {
        var rules: [any ModalityScheduleRule]

        init(rules: [any ModalityScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalitySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalitySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalitySchedule]) -> [String: [String]] {
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

    static func defaultModalityScheduleValidator() -> ModalityScheduleValidator {
        return ModalityScheduleValidator(
            rules: [
                ModalityScheduleCopayRangeRule(min: 9.7, max: 3371.9),
                ModalityScheduleRequiredChecksumRule(message: "modality schedule needs a value"),
                ModalityScheduleAcuityRangeRule(min: 80, max: 86400),
                ModalityScheduleRequiredCodeRule(message: "modality schedule needs an entry"),
                ModalityScheduleScoreRangeRule(min: 2.4, max: 4021.0),
            ]
        )
    }
}
