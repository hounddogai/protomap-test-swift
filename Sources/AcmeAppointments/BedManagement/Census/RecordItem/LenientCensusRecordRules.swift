import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient census record must pass. Check returns its problems, or none.
    protocol LenientCensusRecordRule {
        func check(_ item: LenientCensusRecord) -> [String]
    }

    final class LenientCensusRecordAllowedCodeRule: LenientCensusRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCensusRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class LenientCensusRecordCodeLengthRule: LenientCensusRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCensusRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCensusRecordCopayRangeRule: LenientCensusRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCensusRecord) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientCensusRecordLabelLengthRule: LenientCensusRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCensusRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCensusRecordRequiredLabelRule: LenientCensusRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCensusRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientCensusRecordBatchSizeRangeRule: LenientCensusRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCensusRecord) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient census record.
    final class LenientCensusRecordValidator {
        var rules: [any LenientCensusRecordRule]

        init(rules: [any LenientCensusRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCensusRecord) -> [String] {
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

        func requireValid(_ item: LenientCensusRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCensusRecord]) -> [String: [String]] {
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

    static func defaultLenientCensusRecordValidator() -> LenientCensusRecordValidator {
        return LenientCensusRecordValidator(
            rules: [
                LenientCensusRecordAllowedCodeRule(allowed: ["primary", "rolling", "regional"]),
                LenientCensusRecordCodeLengthRule(maxLength: 16),
                LenientCensusRecordCopayRangeRule(min: 2.1, max: 2931.3),
                LenientCensusRecordLabelLengthRule(maxLength: 16),
                LenientCensusRecordRequiredLabelRule(message: "lenient census record needs this field"),
                LenientCensusRecordBatchSizeRangeRule(min: 86400, max: 86400),
            ]
        )
    }
}
