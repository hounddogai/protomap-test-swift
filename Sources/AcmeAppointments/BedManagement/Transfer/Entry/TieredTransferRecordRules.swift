import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a tiered transfer record must pass. Check returns its problems, or none.
    protocol TieredTransferRecordRule {
        func check(_ item: TieredTransferRecord) -> [String]
    }

    final class TieredTransferRecordCodeLengthRule: TieredTransferRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredTransferRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredTransferRecordAllowedCodeRule: TieredTransferRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredTransferRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class TieredTransferRecordTagsLimitRule: TieredTransferRecordRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: TieredTransferRecord) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class TieredTransferRecordWindowDaysRangeRule: TieredTransferRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredTransferRecord) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredTransferRecordRequiredCodeRule: TieredTransferRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredTransferRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredTransferRecordDiscountRangeRule: TieredTransferRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredTransferRecord) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered transfer record.
    final class TieredTransferRecordValidator {
        var rules: [any TieredTransferRecordRule]

        init(rules: [any TieredTransferRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredTransferRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredTransferRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredTransferRecord]) -> [String: [String]] {
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

    static func defaultTieredTransferRecordValidator() -> TieredTransferRecordValidator {
        return TieredTransferRecordValidator(
            rules: [
                TieredTransferRecordCodeLengthRule(maxLength: 32),
                TieredTransferRecordAllowedCodeRule(allowed: ["rolling"]),
                TieredTransferRecordTagsLimitRule(maxCount: 80, banned: ["weighted", "lenient", "weighted"]),
                TieredTransferRecordWindowDaysRangeRule(min: 255, max: 86400),
                TieredTransferRecordRequiredCodeRule(message: "tiered transfer record needs a value"),
                TieredTransferRecordDiscountRangeRule(min: 4.2, max: 2089.2),
            ]
        )
    }
}
