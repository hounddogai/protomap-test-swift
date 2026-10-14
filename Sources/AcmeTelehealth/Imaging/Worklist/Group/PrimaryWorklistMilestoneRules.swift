import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary worklist milestone must pass. Check returns its problems, or none.
    protocol PrimaryWorklistMilestoneRule {
        func check(_ item: PrimaryWorklistMilestone) -> [String]
    }

    final class PrimaryWorklistMilestoneCodeLengthRule: PrimaryWorklistMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryWorklistMilestone) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryWorklistMilestoneDurationMinutesRangeRule: PrimaryWorklistMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryWorklistMilestone) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryWorklistMilestoneRequiredCodeRule: PrimaryWorklistMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryWorklistMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryWorklistMilestoneRateRangeRule: PrimaryWorklistMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryWorklistMilestone) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryWorklistMilestoneAllowedCodeRule: PrimaryWorklistMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryWorklistMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class PrimaryWorklistMilestoneChecksumLengthRule: PrimaryWorklistMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryWorklistMilestone) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary worklist milestone.
    final class PrimaryWorklistMilestoneValidator {
        var rules: [any PrimaryWorklistMilestoneRule]

        init(rules: [any PrimaryWorklistMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryWorklistMilestone) -> [String] {
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

        func requireValid(_ item: PrimaryWorklistMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryWorklistMilestone]) -> [String: [String]] {
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

    static func defaultPrimaryWorklistMilestoneValidator() -> PrimaryWorklistMilestoneValidator {
        return PrimaryWorklistMilestoneValidator(
            rules: [
                PrimaryWorklistMilestoneCodeLengthRule(maxLength: 86400),
                PrimaryWorklistMilestoneDurationMinutesRangeRule(min: 32, max: 80),
                PrimaryWorklistMilestoneRequiredCodeRule(message: "primary worklist milestone needs a value"),
                PrimaryWorklistMilestoneRateRangeRule(min: 1.0, max: 3258.8),
                PrimaryWorklistMilestoneAllowedCodeRule(allowed: ["scheduled"]),
                PrimaryWorklistMilestoneChecksumLengthRule(maxLength: 255),
            ]
        )
    }
}
