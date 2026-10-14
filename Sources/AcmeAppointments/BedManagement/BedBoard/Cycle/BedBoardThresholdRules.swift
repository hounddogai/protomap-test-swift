import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board threshold must pass. Check returns its problems, or none.
    protocol BedBoardThresholdRule {
        func check(_ item: BedBoardThreshold) -> [String]
    }

    final class BedBoardThresholdRequiredTitleRule: BedBoardThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardThresholdCopayRangeRule: BedBoardThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardThreshold) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BedBoardThresholdFacilityLengthRule: BedBoardThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardThreshold) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardThresholdRequiredCodeRule: BedBoardThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardThresholdCreatedAtRangeRule: BedBoardThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BedBoardThreshold) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board threshold.
    final class BedBoardThresholdValidator {
        var rules: [any BedBoardThresholdRule]

        init(rules: [any BedBoardThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardThreshold) -> [String] {
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

        func requireValid(_ item: BedBoardThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardThreshold]) -> [String: [String]] {
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

    static func defaultBedBoardThresholdValidator() -> BedBoardThresholdValidator {
        return BedBoardThresholdValidator(
            rules: [
                BedBoardThresholdRequiredTitleRule(message: "bed board threshold needs this field"),
                BedBoardThresholdCopayRangeRule(min: 4.5, max: 3857.8),
                BedBoardThresholdFacilityLengthRule(maxLength: 80),
                BedBoardThresholdRequiredCodeRule(message: "bed board threshold needs an entry"),
                BedBoardThresholdCreatedAtRangeRule(min: 120, max: 1000),
            ]
        )
    }
}
