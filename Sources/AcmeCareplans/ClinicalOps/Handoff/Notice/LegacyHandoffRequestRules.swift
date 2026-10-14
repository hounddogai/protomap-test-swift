import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a legacy handoff request must pass. Check returns its problems, or none.
    protocol LegacyHandoffRequestRule {
        func check(_ item: LegacyHandoffRequest) -> [String]
    }

    final class LegacyHandoffRequestMinimumRangeRule: LegacyHandoffRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyHandoffRequest) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyHandoffRequestArchivedGuardRule: LegacyHandoffRequestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyHandoffRequest) -> [String] {
            if item.archived && (item.graceDays > limit) {
                return ["grace days \(item.graceDays) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class LegacyHandoffRequestRequiredLabelRule: LegacyHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyHandoffRequest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyHandoffRequestGraceDaysRangeRule: LegacyHandoffRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyHandoffRequest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyHandoffRequestRequiredCodeRule: LegacyHandoffRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyHandoffRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyHandoffRequestLabelLengthRule: LegacyHandoffRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyHandoffRequest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy handoff request.
    final class LegacyHandoffRequestValidator {
        var rules: [any LegacyHandoffRequestRule]

        init(rules: [any LegacyHandoffRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyHandoffRequest) -> [String] {
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

        func requireValid(_ item: LegacyHandoffRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyHandoffRequest]) -> [String: [String]] {
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

    static func defaultLegacyHandoffRequestValidator() -> LegacyHandoffRequestValidator {
        return LegacyHandoffRequestValidator(
            rules: [
                LegacyHandoffRequestMinimumRangeRule(min: 3.2, max: 1185.4),
                LegacyHandoffRequestArchivedGuardRule(limit: 255),
                LegacyHandoffRequestRequiredLabelRule(message: "legacy handoff request needs this field"),
                LegacyHandoffRequestGraceDaysRangeRule(min: 32, max: 3600),
                LegacyHandoffRequestRequiredCodeRule(message: "legacy handoff request needs an entry"),
                LegacyHandoffRequestLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
