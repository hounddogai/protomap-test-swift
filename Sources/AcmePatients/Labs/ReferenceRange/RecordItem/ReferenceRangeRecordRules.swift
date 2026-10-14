import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range record must pass. Check returns its problems, or none.
    protocol ReferenceRangeRecordRule {
        func check(_ item: ReferenceRangeRecord) -> [String]
    }

    final class ReferenceRangeRecordMinimumRangeRule: ReferenceRangeRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeRecord) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeRecordAllowedNameRule: ReferenceRangeRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class ReferenceRangeRecordCodeLengthRule: ReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeRecordBedLengthRule: ReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeRecord) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeRecordNameLengthRule: ReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range record.
    final class ReferenceRangeRecordValidator {
        var rules: [any ReferenceRangeRecordRule]

        init(rules: [any ReferenceRangeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeRecord]) -> [String: [String]] {
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

    static func defaultReferenceRangeRecordValidator() -> ReferenceRangeRecordValidator {
        return ReferenceRangeRecordValidator(
            rules: [
                ReferenceRangeRecordMinimumRangeRule(min: 9.9, max: 4966.6),
                ReferenceRangeRecordAllowedNameRule(allowed: []),
                ReferenceRangeRecordCodeLengthRule(maxLength: 1000),
                ReferenceRangeRecordBedLengthRule(maxLength: 86400),
                ReferenceRangeRecordNameLengthRule(maxLength: 255),
            ]
        )
    }
}
