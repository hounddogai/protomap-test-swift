import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a rolling modality claim must pass. Check returns its problems, or none.
    protocol RollingModalityClaimRule {
        func check(_ item: RollingModalityClaim) -> [String]
    }

    final class RollingModalityClaimRequiredWardRule: RollingModalityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingModalityClaim) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingModalityClaimWardLengthRule: RollingModalityClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingModalityClaim) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingModalityClaimUnitLengthRule: RollingModalityClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingModalityClaim) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingModalityClaimRevisionRangeRule: RollingModalityClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingModalityClaim) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingModalityClaimRequiredNameRule: RollingModalityClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingModalityClaim) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling modality claim.
    final class RollingModalityClaimValidator {
        var rules: [any RollingModalityClaimRule]

        init(rules: [any RollingModalityClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingModalityClaim) -> [String] {
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

        func requireValid(_ item: RollingModalityClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingModalityClaim]) -> [String: [String]] {
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

    static func defaultRollingModalityClaimValidator() -> RollingModalityClaimValidator {
        return RollingModalityClaimValidator(
            rules: [
                RollingModalityClaimRequiredWardRule(message: "rolling modality claim needs an entry"),
                RollingModalityClaimWardLengthRule(maxLength: 80),
                RollingModalityClaimUnitLengthRule(maxLength: 3600),
                RollingModalityClaimRevisionRangeRule(min: 16, max: 120),
                RollingModalityClaimRequiredNameRule(message: "rolling modality claim needs a value"),
            ]
        )
    }
}
