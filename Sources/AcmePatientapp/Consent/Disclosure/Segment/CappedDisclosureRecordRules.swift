import AcmePlatform
import Foundation

extension Consent {
    /// A rule a capped disclosure record must pass. Check returns its problems, or none.
    protocol CappedDisclosureRecordRule {
        func check(_ item: CappedDisclosureRecord) -> [String]
    }

    final class CappedDisclosureRecordLabelLengthRule: CappedDisclosureRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDisclosureRecord) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedDisclosureRecordRegionLengthRule: CappedDisclosureRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDisclosureRecord) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedDisclosureRecordPriorityRangeRule: CappedDisclosureRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedDisclosureRecord) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedDisclosureRecordCodePrefixRule: CappedDisclosureRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedDisclosureRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedDisclosureRecordCodeLengthRule: CappedDisclosureRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedDisclosureRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped disclosure record.
    final class CappedDisclosureRecordValidator {
        var rules: [any CappedDisclosureRecordRule]

        init(rules: [any CappedDisclosureRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedDisclosureRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedDisclosureRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedDisclosureRecord]) -> [String: [String]] {
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

    static func defaultCappedDisclosureRecordValidator() -> CappedDisclosureRecordValidator {
        return CappedDisclosureRecordValidator(
            rules: [
                CappedDisclosureRecordLabelLengthRule(maxLength: 120),
                CappedDisclosureRecordRegionLengthRule(maxLength: 86400),
                CappedDisclosureRecordPriorityRangeRule(min: 64, max: 1000),
                CappedDisclosureRecordCodePrefixRule(prefix: "X"),
                CappedDisclosureRecordCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
