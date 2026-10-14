import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census adjustment must pass. Check returns its problems, or none.
    protocol CensusAdjustmentRule {
        func check(_ item: CensusAdjustment) -> [String]
    }

    final class CensusAdjustmentWardLengthRule: CensusAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAdjustment) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusAdjustmentCeilingRangeRule: CensusAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusAdjustment) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusAdjustmentTagsLimitRule: CensusAdjustmentRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: CensusAdjustment) -> [String] {
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

    final class CensusAdjustmentCodePrefixRule: CensusAdjustmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusAdjustment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusAdjustmentTitleLengthRule: CensusAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusAdjustment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusAdjustmentRequiredWardRule: CensusAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusAdjustment) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a census adjustment.
    final class CensusAdjustmentValidator {
        var rules: [any CensusAdjustmentRule]

        init(rules: [any CensusAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusAdjustment) -> [String] {
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

        func requireValid(_ item: CensusAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusAdjustment]) -> [String: [String]] {
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

    static func defaultCensusAdjustmentValidator() -> CensusAdjustmentValidator {
        return CensusAdjustmentValidator(
            rules: [
                CensusAdjustmentWardLengthRule(maxLength: 120),
                CensusAdjustmentCeilingRangeRule(min: 1.0, max: 2077.7),
                CensusAdjustmentTagsLimitRule(maxCount: 255, banned: []),
                CensusAdjustmentCodePrefixRule(prefix: "REF"),
                CensusAdjustmentTitleLengthRule(maxLength: 3600),
                CensusAdjustmentRequiredWardRule(message: "census adjustment needs an entry"),
            ]
        )
    }
}
