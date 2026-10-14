import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal inventory notice must pass. Check returns its problems, or none.
    protocol SeasonalInventoryNoticeRule {
        func check(_ item: SeasonalInventoryNotice) -> [String]
    }

    final class SeasonalInventoryNoticeRequiredCodeRule: SeasonalInventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInventoryNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInventoryNoticeRequiredRegionRule: SeasonalInventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInventoryNotice) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInventoryNoticeBedLengthRule: SeasonalInventoryNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInventoryNotice) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalInventoryNoticeTitleLengthRule: SeasonalInventoryNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInventoryNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalInventoryNoticeCodePrefixRule: SeasonalInventoryNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalInventoryNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal inventory notice.
    final class SeasonalInventoryNoticeValidator {
        var rules: [any SeasonalInventoryNoticeRule]

        init(rules: [any SeasonalInventoryNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalInventoryNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalInventoryNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalInventoryNotice]) -> [String: [String]] {
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

    static func defaultSeasonalInventoryNoticeValidator() -> SeasonalInventoryNoticeValidator {
        return SeasonalInventoryNoticeValidator(
            rules: [
                SeasonalInventoryNoticeRequiredCodeRule(message: "seasonal inventory notice needs an entry"),
                SeasonalInventoryNoticeRequiredRegionRule(message: "seasonal inventory notice needs a value"),
                SeasonalInventoryNoticeBedLengthRule(maxLength: 1000),
                SeasonalInventoryNoticeTitleLengthRule(maxLength: 64),
                SeasonalInventoryNoticeCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
