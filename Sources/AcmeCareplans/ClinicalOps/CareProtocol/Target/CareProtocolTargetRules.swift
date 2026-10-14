import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol target must pass. Check returns its problems, or none.
    protocol CareProtocolTargetRule {
        func check(_ item: CareProtocolTarget) -> [String]
    }

    final class CareProtocolTargetUpdatedAtRangeRule: CareProtocolTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTarget) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CareProtocolTargetRequiredCodeRule: CareProtocolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolTargetDurationMinutesRangeRule: CareProtocolTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolTarget) -> [String] {
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

    final class CareProtocolTargetRequiredExternalRefRule: CareProtocolTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolTarget) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol target.
    final class CareProtocolTargetValidator {
        var rules: [any CareProtocolTargetRule]

        init(rules: [any CareProtocolTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolTarget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolTarget]) -> [String: [String]] {
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

    static func defaultCareProtocolTargetValidator() -> CareProtocolTargetValidator {
        return CareProtocolTargetValidator(
            rules: [
                CareProtocolTargetUpdatedAtRangeRule(min: 3600, max: 86400),
                CareProtocolTargetRequiredCodeRule(message: "care protocol target needs an entry"),
                CareProtocolTargetDurationMinutesRangeRule(min: 120, max: 3600),
                CareProtocolTargetRequiredExternalRefRule(message: "care protocol target needs an entry"),
            ]
        )
    }
}
