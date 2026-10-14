import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling specimen entry must pass. Check returns its problems, or none.
    protocol RollingSpecimenEntryRule {
        func check(_ item: RollingSpecimenEntry) -> [String]
    }

    final class RollingSpecimenEntrySpecialtyLengthRule: RollingSpecimenEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSpecimenEntry) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSpecimenEntryCodeLengthRule: RollingSpecimenEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingSpecimenEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingSpecimenEntryMinimumRangeRule: RollingSpecimenEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSpecimenEntry) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingSpecimenEntryLimitRangeRule: RollingSpecimenEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingSpecimenEntry) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingSpecimenEntryAllowedSpecialtyRule: RollingSpecimenEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingSpecimenEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling specimen entry.
    final class RollingSpecimenEntryValidator {
        var rules: [any RollingSpecimenEntryRule]

        init(rules: [any RollingSpecimenEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingSpecimenEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingSpecimenEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingSpecimenEntry]) -> [String: [String]] {
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

    static func defaultRollingSpecimenEntryValidator() -> RollingSpecimenEntryValidator {
        return RollingSpecimenEntryValidator(
            rules: [
                RollingSpecimenEntrySpecialtyLengthRule(maxLength: 120),
                RollingSpecimenEntryCodeLengthRule(maxLength: 80),
                RollingSpecimenEntryMinimumRangeRule(min: 8.7, max: 4521.6),
                RollingSpecimenEntryLimitRangeRule(min: 80, max: 3600),
                RollingSpecimenEntryAllowedSpecialtyRule(allowed: ["regional"]),
            ]
        )
    }
}
