import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a tiered overtime score must pass. Check returns its problems, or none.
    protocol TieredOvertimeScoreRule {
        func check(_ item: TieredOvertimeScore) -> [String]
    }

    final class TieredOvertimeScoreFloorValueRangeRule: TieredOvertimeScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredOvertimeScore) -> [String] {
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

    final class TieredOvertimeScoreLabelLengthRule: TieredOvertimeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOvertimeScore) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOvertimeScoreChannelLengthRule: TieredOvertimeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOvertimeScore) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOvertimeScoreAllowedChannelRule: TieredOvertimeScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredOvertimeScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is too long"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered overtime score.
    final class TieredOvertimeScoreValidator {
        var rules: [any TieredOvertimeScoreRule]

        init(rules: [any TieredOvertimeScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOvertimeScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredOvertimeScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOvertimeScore]) -> [String: [String]] {
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

    static func defaultTieredOvertimeScoreValidator() -> TieredOvertimeScoreValidator {
        return TieredOvertimeScoreValidator(
            rules: [
                TieredOvertimeScoreFloorValueRangeRule(min: 9.3, max: 4050.7),
                TieredOvertimeScoreLabelLengthRule(maxLength: 16),
                TieredOvertimeScoreChannelLengthRule(maxLength: 64),
                TieredOvertimeScoreAllowedChannelRule(allowed: ["global"]),
            ]
        )
    }
}
