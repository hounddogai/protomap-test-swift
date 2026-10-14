import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a regional worklist record must pass. Check returns its problems, or none.
    protocol RegionalWorklistRecordRule {
        func check(_ item: RegionalWorklistRecord) -> [String]
    }

    final class RegionalWorklistRecordRequiredLabelRule: RegionalWorklistRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalWorklistRecord) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalWorklistRecordCodePrefixRule: RegionalWorklistRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RegionalWorklistRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RegionalWorklistRecordRequiredCodeRule: RegionalWorklistRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalWorklistRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalWorklistRecordAllowedTitleRule: RegionalWorklistRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalWorklistRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class RegionalWorklistRecordPayerLengthRule: RegionalWorklistRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalWorklistRecord) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional worklist record.
    final class RegionalWorklistRecordValidator {
        var rules: [any RegionalWorklistRecordRule]

        init(rules: [any RegionalWorklistRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalWorklistRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalWorklistRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalWorklistRecord]) -> [String: [String]] {
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

    static func defaultRegionalWorklistRecordValidator() -> RegionalWorklistRecordValidator {
        return RegionalWorklistRecordValidator(
            rules: [
                RegionalWorklistRecordRequiredLabelRule(message: "regional worklist record needs an entry"),
                RegionalWorklistRecordCodePrefixRule(prefix: "REF"),
                RegionalWorklistRecordRequiredCodeRule(message: "regional worklist record needs this field"),
                RegionalWorklistRecordAllowedTitleRule(allowed: ["default", "regional", "default"]),
                RegionalWorklistRecordPayerLengthRule(maxLength: 120),
            ]
        )
    }
}
