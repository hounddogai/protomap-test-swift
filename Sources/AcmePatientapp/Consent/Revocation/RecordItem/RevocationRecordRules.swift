import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation record must pass. Check returns its problems, or none.
    protocol RevocationRecordRule {
        func check(_ item: RevocationRecord) -> [String]
    }

    final class RevocationRecordWindowDaysRangeRule: RevocationRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationRecord) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RevocationRecordLabelLengthRule: RevocationRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationRecordCodePrefixRule: RevocationRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RevocationRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RevocationRecordCodeLengthRule: RevocationRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation record.
    final class RevocationRecordValidator {
        var rules: [any RevocationRecordRule]

        init(rules: [any RevocationRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationRecord]) -> [String: [String]] {
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

    static func defaultRevocationRecordValidator() -> RevocationRecordValidator {
        return RevocationRecordValidator(
            rules: [
                RevocationRecordWindowDaysRangeRule(min: 16, max: 64),
                RevocationRecordLabelLengthRule(maxLength: 3600),
                RevocationRecordCodePrefixRule(prefix: "X"),
                RevocationRecordCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
