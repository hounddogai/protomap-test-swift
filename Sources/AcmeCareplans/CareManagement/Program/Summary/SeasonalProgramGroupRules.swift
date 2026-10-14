import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal program group must pass. Check returns its problems, or none.
    protocol SeasonalProgramGroupRule {
        func check(_ item: SeasonalProgramGroup) -> [String]
    }

    final class SeasonalProgramGroupAllowedNameRule: SeasonalProgramGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalProgramGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class SeasonalProgramGroupPhoneLengthRule: SeasonalProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalProgramGroup) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalProgramGroupArchivedGuardRule: SeasonalProgramGroupRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SeasonalProgramGroup) -> [String] {
            if item.archived && (item.amount > limit) {
                return ["amount \(item.amount) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SeasonalProgramGroupLabelLengthRule: SeasonalProgramGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalProgramGroup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal program group.
    final class SeasonalProgramGroupValidator {
        var rules: [any SeasonalProgramGroupRule]

        init(rules: [any SeasonalProgramGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalProgramGroup) -> [String] {
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

        func requireValid(_ item: SeasonalProgramGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalProgramGroup]) -> [String: [String]] {
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

    static func defaultSeasonalProgramGroupValidator() -> SeasonalProgramGroupValidator {
        return SeasonalProgramGroupValidator(
            rules: [
                SeasonalProgramGroupAllowedNameRule(allowed: []),
                SeasonalProgramGroupPhoneLengthRule(maxLength: 255),
                SeasonalProgramGroupArchivedGuardRule(limit: 0.1),
                SeasonalProgramGroupLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
