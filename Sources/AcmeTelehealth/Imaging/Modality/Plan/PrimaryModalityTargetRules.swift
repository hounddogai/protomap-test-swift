import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a primary modality target must pass. Check returns its problems, or none.
    protocol PrimaryModalityTargetRule {
        func check(_ item: PrimaryModalityTarget) -> [String]
    }

    final class PrimaryModalityTargetArchivedGuardRule: PrimaryModalityTargetRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimaryModalityTarget) -> [String] {
            if item.archived && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PrimaryModalityTargetRequiredCodeRule: PrimaryModalityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryModalityTarget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryModalityTargetVisitMinutesRangeRule: PrimaryModalityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryModalityTarget) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryModalityTargetRequiredCountryRule: PrimaryModalityTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryModalityTarget) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryModalityTargetLimitRangeRule: PrimaryModalityTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryModalityTarget) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary modality target.
    final class PrimaryModalityTargetValidator {
        var rules: [any PrimaryModalityTargetRule]

        init(rules: [any PrimaryModalityTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryModalityTarget) -> [String] {
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

        func requireValid(_ item: PrimaryModalityTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryModalityTarget]) -> [String: [String]] {
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

    static func defaultPrimaryModalityTargetValidator() -> PrimaryModalityTargetValidator {
        return PrimaryModalityTargetValidator(
            rules: [
                PrimaryModalityTargetArchivedGuardRule(limit: 32),
                PrimaryModalityTargetRequiredCodeRule(message: "primary modality target needs a value"),
                PrimaryModalityTargetVisitMinutesRangeRule(min: 32, max: 3600),
                PrimaryModalityTargetRequiredCountryRule(message: "primary modality target needs this field"),
                PrimaryModalityTargetLimitRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
