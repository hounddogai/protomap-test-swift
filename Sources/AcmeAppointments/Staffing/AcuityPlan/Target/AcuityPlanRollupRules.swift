import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a acuity plan rollup must pass. Check returns its problems, or none.
    protocol AcuityPlanRollupRule {
        func check(_ item: AcuityPlanRollup) -> [String]
    }

    final class AcuityPlanRollupDurationMinutesRangeRule: AcuityPlanRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AcuityPlanRollup) -> [String] {
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

    final class AcuityPlanRollupRequiredCodeRule: AcuityPlanRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AcuityPlanRollupExternalRefLengthRule: AcuityPlanRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanRollup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanRollupFacilityLengthRule: AcuityPlanRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AcuityPlanRollup) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AcuityPlanRollupRequiredExternalRefRule: AcuityPlanRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AcuityPlanRollup) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a acuity plan rollup.
    final class AcuityPlanRollupValidator {
        var rules: [any AcuityPlanRollupRule]

        init(rules: [any AcuityPlanRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: AcuityPlanRollup) -> [String] {
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

        func requireValid(_ item: AcuityPlanRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AcuityPlanRollup]) -> [String: [String]] {
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

    static func defaultAcuityPlanRollupValidator() -> AcuityPlanRollupValidator {
        return AcuityPlanRollupValidator(
            rules: [
                AcuityPlanRollupDurationMinutesRangeRule(min: 32, max: 1000),
                AcuityPlanRollupRequiredCodeRule(message: "acuity plan rollup needs this field"),
                AcuityPlanRollupExternalRefLengthRule(maxLength: 16),
                AcuityPlanRollupFacilityLengthRule(maxLength: 64),
                AcuityPlanRollupRequiredExternalRefRule(message: "acuity plan rollup needs an entry"),
            ]
        )
    }
}
