import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default task record must pass. Check returns its problems, or none.
    protocol DefaultTaskRecordRule {
        func check(_ item: DefaultTaskRecord) -> [String]
    }

    final class DefaultTaskRecordRegionLengthRule: DefaultTaskRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultTaskRecord) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultTaskRecordRequiredDiagnosisCodeRule: DefaultTaskRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTaskRecord) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultTaskRecordMinimumRangeRule: DefaultTaskRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultTaskRecord) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultTaskRecordRequiredRegionRule: DefaultTaskRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultTaskRecord) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default task record.
    final class DefaultTaskRecordValidator {
        var rules: [any DefaultTaskRecordRule]

        init(rules: [any DefaultTaskRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultTaskRecord) -> [String] {
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

        func requireValid(_ item: DefaultTaskRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultTaskRecord]) -> [String: [String]] {
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

    static func defaultDefaultTaskRecordValidator() -> DefaultTaskRecordValidator {
        return DefaultTaskRecordValidator(
            rules: [
                DefaultTaskRecordRegionLengthRule(maxLength: 64),
                DefaultTaskRecordRequiredDiagnosisCodeRule(message: "default task record needs a value"),
                DefaultTaskRecordMinimumRangeRule(min: 2.5, max: 4340.0),
                DefaultTaskRecordRequiredRegionRule(message: "default task record needs a value"),
            ]
        )
    }
}
