import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted interaction record must pass. Check returns its problems, or none.
    protocol WeightedInteractionRecordRule {
        func check(_ item: WeightedInteractionRecord) -> [String]
    }

    final class WeightedInteractionRecordRequiredOwnerIDRule: WeightedInteractionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInteractionRecord) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedInteractionRecordStartsAtRangeRule: WeightedInteractionRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInteractionRecord) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedInteractionRecordTitleLengthRule: WeightedInteractionRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedInteractionRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedInteractionRecordRequiredTitleRule: WeightedInteractionRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInteractionRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted interaction record.
    final class WeightedInteractionRecordValidator {
        var rules: [any WeightedInteractionRecordRule]

        init(rules: [any WeightedInteractionRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedInteractionRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedInteractionRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedInteractionRecord]) -> [String: [String]] {
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

    static func defaultWeightedInteractionRecordValidator() -> WeightedInteractionRecordValidator {
        return WeightedInteractionRecordValidator(
            rules: [
                WeightedInteractionRecordRequiredOwnerIDRule(message: "weighted interaction record needs this field"),
                WeightedInteractionRecordStartsAtRangeRule(min: 32, max: 80),
                WeightedInteractionRecordTitleLengthRule(maxLength: 86400),
                WeightedInteractionRecordRequiredTitleRule(message: "weighted interaction record needs an entry"),
            ]
        )
    }
}
