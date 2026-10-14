import AcmePlatform
import Foundation

extension Labs {
    /// A rule a regional specimen record must pass. Check returns its problems, or none.
    protocol RegionalSpecimenRecordRule {
        func check(_ item: RegionalSpecimenRecord) -> [String]
    }

    final class RegionalSpecimenRecordScoreRangeRule: RegionalSpecimenRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSpecimenRecord) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalSpecimenRecordFloorValueRangeRule: RegionalSpecimenRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalSpecimenRecord) -> [String] {
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

    final class RegionalSpecimenRecordCodeLengthRule: RegionalSpecimenRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalSpecimenRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalSpecimenRecordAllowedCodeRule: RegionalSpecimenRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalSpecimenRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class RegionalSpecimenRecordRequiredCodeRule: RegionalSpecimenRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSpecimenRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalSpecimenRecordRequiredTitleRule: RegionalSpecimenRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalSpecimenRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional specimen record.
    final class RegionalSpecimenRecordValidator {
        var rules: [any RegionalSpecimenRecordRule]

        init(rules: [any RegionalSpecimenRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalSpecimenRecord) -> [String] {
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

        func requireValid(_ item: RegionalSpecimenRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalSpecimenRecord]) -> [String: [String]] {
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

    static func defaultRegionalSpecimenRecordValidator() -> RegionalSpecimenRecordValidator {
        return RegionalSpecimenRecordValidator(
            rules: [
                RegionalSpecimenRecordScoreRangeRule(min: 0.1, max: 4802.7),
                RegionalSpecimenRecordFloorValueRangeRule(min: 7.2, max: 4363.0),
                RegionalSpecimenRecordCodeLengthRule(maxLength: 86400),
                RegionalSpecimenRecordAllowedCodeRule(allowed: ["regional", "legacy"]),
                RegionalSpecimenRecordRequiredCodeRule(message: "regional specimen record needs this field"),
                RegionalSpecimenRecordRequiredTitleRule(message: "regional specimen record needs an entry"),
            ]
        )
    }
}
