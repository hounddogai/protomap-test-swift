import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a regional census request must pass. Check returns its problems, or none.
    protocol RegionalCensusRequestRule {
        func check(_ item: RegionalCensusRequest) -> [String]
    }

    final class RegionalCensusRequestTagsLimitRule: RegionalCensusRequestRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: RegionalCensusRequest) -> [String] {
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

    final class RegionalCensusRequestCodeLengthRule: RegionalCensusRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCensusRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCensusRequestNameLengthRule: RegionalCensusRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCensusRequest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCensusRequestRequiredSummaryRule: RegionalCensusRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCensusRequest) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCensusRequestRateRangeRule: RegionalCensusRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCensusRequest) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RegionalCensusRequestRequiredCodeRule: RegionalCensusRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCensusRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional census request.
    final class RegionalCensusRequestValidator {
        var rules: [any RegionalCensusRequestRule]

        init(rules: [any RegionalCensusRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCensusRequest) -> [String] {
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

        func requireValid(_ item: RegionalCensusRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCensusRequest]) -> [String: [String]] {
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

    static func defaultRegionalCensusRequestValidator() -> RegionalCensusRequestValidator {
        return RegionalCensusRequestValidator(
            rules: [
                RegionalCensusRequestTagsLimitRule(maxCount: 255, banned: ["capped", "manual"]),
                RegionalCensusRequestCodeLengthRule(maxLength: 86400),
                RegionalCensusRequestNameLengthRule(maxLength: 32),
                RegionalCensusRequestRequiredSummaryRule(message: "regional census request needs an entry"),
                RegionalCensusRequestRateRangeRule(min: 9.9, max: 4970.6),
                RegionalCensusRequestRequiredCodeRule(message: "regional census request needs a value"),
            ]
        )
    }
}
