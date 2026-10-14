import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen notice must pass. Check returns its problems, or none.
    protocol SpecimenNoticeRule {
        func check(_ item: SpecimenNotice) -> [String]
    }

    final class SpecimenNoticeCodeLengthRule: SpecimenNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenNoticeMarginRangeRule: SpecimenNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenNotice) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SpecimenNoticeRequiredCodeRule: SpecimenNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenNoticeRequiredLocaleRule: SpecimenNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenNotice) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenNoticeCodePrefixRule: SpecimenNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SpecimenNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SpecimenNoticeCeilingRangeRule: SpecimenNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SpecimenNotice) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a specimen notice.
    final class SpecimenNoticeValidator {
        var rules: [any SpecimenNoticeRule]

        init(rules: [any SpecimenNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenNotice) -> [String] {
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

        func requireValid(_ item: SpecimenNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenNotice]) -> [String: [String]] {
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

    static func defaultSpecimenNoticeValidator() -> SpecimenNoticeValidator {
        return SpecimenNoticeValidator(
            rules: [
                SpecimenNoticeCodeLengthRule(maxLength: 3600),
                SpecimenNoticeMarginRangeRule(min: 5.6, max: 460.8),
                SpecimenNoticeRequiredCodeRule(message: "specimen notice needs this field"),
                SpecimenNoticeRequiredLocaleRule(message: "specimen notice needs this field"),
                SpecimenNoticeCodePrefixRule(prefix: "REF"),
                SpecimenNoticeCeilingRangeRule(min: 1.0, max: 4172.9),
            ]
        )
    }
}
