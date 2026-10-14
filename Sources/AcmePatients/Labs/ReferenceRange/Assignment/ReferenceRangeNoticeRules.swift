import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range notice must pass. Check returns its problems, or none.
    protocol ReferenceRangeNoticeRule {
        func check(_ item: ReferenceRangeNotice) -> [String]
    }

    final class ReferenceRangeNoticeAllergyLengthRule: ReferenceRangeNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeNotice) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeNoticeLimitRangeRule: ReferenceRangeNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ReferenceRangeNotice) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ReferenceRangeNoticeRequiredAllergyRule: ReferenceRangeNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeNotice) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeNoticeAllowedCodeRule: ReferenceRangeNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ReferenceRangeNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class ReferenceRangeNoticeUnitLengthRule: ReferenceRangeNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeNotice) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeNoticeCodePrefixRule: ReferenceRangeNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ReferenceRangeNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a reference range notice.
    final class ReferenceRangeNoticeValidator {
        var rules: [any ReferenceRangeNoticeRule]

        init(rules: [any ReferenceRangeNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeNotice) -> [String] {
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

        func requireValid(_ item: ReferenceRangeNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeNotice]) -> [String: [String]] {
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

    static func defaultReferenceRangeNoticeValidator() -> ReferenceRangeNoticeValidator {
        return ReferenceRangeNoticeValidator(
            rules: [
                ReferenceRangeNoticeAllergyLengthRule(maxLength: 86400),
                ReferenceRangeNoticeLimitRangeRule(min: 64, max: 80),
                ReferenceRangeNoticeRequiredAllergyRule(message: "reference range notice needs this field"),
                ReferenceRangeNoticeAllowedCodeRule(allowed: ["batched", "strict", "capped"]),
                ReferenceRangeNoticeUnitLengthRule(maxLength: 255),
                ReferenceRangeNoticeCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
