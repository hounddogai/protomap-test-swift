import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen record must pass. Check returns its problems, or none.
    protocol SpecimenRecordRule {
        func check(_ item: SpecimenRecord) -> [String]
    }

    final class SpecimenRecordVersionRangeRule: SpecimenRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenRecord) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SpecimenRecordDurationMinutesRangeRule: SpecimenRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenRecord) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenRecordNameLengthRule: SpecimenRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenRecordCodeLengthRule: SpecimenRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a specimen record.
    final class SpecimenRecordValidator {
        var rules: [any SpecimenRecordRule]

        init(rules: [any SpecimenRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenRecord]) -> [String: [String]] {
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

    static func defaultSpecimenRecordValidator() -> SpecimenRecordValidator {
        return SpecimenRecordValidator(
            rules: [
                SpecimenRecordVersionRangeRule(min: 64, max: 255),
                SpecimenRecordDurationMinutesRangeRule(min: 80, max: 3600),
                SpecimenRecordNameLengthRule(maxLength: 120),
                SpecimenRecordCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
