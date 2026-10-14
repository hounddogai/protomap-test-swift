import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census notice must pass. Check returns its problems, or none.
    protocol CensusNoticeRule {
        func check(_ item: CensusNotice) -> [String]
    }

    final class CensusNoticeAmountRangeRule: CensusNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusNotice) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusNoticeCapacityRangeRule: CensusNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusNotice) -> [String] {
            let value = item.capacity
            if value < min || value > max {
                return ["capacity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusNoticeCodePrefixRule: CensusNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusNoticeTitleLengthRule: CensusNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusNoticeAllowedTitleRule: CensusNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class CensusNoticeTimezoneLengthRule: CensusNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusNotice) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a census notice.
    final class CensusNoticeValidator {
        var rules: [any CensusNoticeRule]

        init(rules: [any CensusNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusNotice]) -> [String: [String]] {
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

    static func defaultCensusNoticeValidator() -> CensusNoticeValidator {
        return CensusNoticeValidator(
            rules: [
                CensusNoticeAmountRangeRule(min: 3.4, max: 1771.5),
                CensusNoticeCapacityRangeRule(min: 80, max: 255),
                CensusNoticeCodePrefixRule(prefix: "REF"),
                CensusNoticeTitleLengthRule(maxLength: 3600),
                CensusNoticeAllowedTitleRule(allowed: ["global", "adaptive"]),
                CensusNoticeTimezoneLengthRule(maxLength: 1000),
            ]
        )
    }
}
