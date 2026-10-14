import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure notice must pass. Check returns its problems, or none.
    protocol DisclosureNoticeRule {
        func check(_ item: DisclosureNotice) -> [String]
    }

    final class DisclosureNoticeAllowedPhoneRule: DisclosureNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is missing"]
            }
            return []
        }
    }

    final class DisclosureNoticeDiscountRangeRule: DisclosureNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DisclosureNotice) -> [String] {
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

    final class DisclosureNoticeRequiredPayerRule: DisclosureNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureNotice) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureNoticePayerLengthRule: DisclosureNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DisclosureNotice) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure notice.
    final class DisclosureNoticeValidator {
        var rules: [any DisclosureNoticeRule]

        init(rules: [any DisclosureNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureNotice) -> [String] {
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

        func requireValid(_ item: DisclosureNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureNotice]) -> [String: [String]] {
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

    static func defaultDisclosureNoticeValidator() -> DisclosureNoticeValidator {
        return DisclosureNoticeValidator(
            rules: [
                DisclosureNoticeAllowedPhoneRule(allowed: []),
                DisclosureNoticeDiscountRangeRule(min: 3.1, max: 3045.6),
                DisclosureNoticeRequiredPayerRule(message: "disclosure notice needs this field"),
                DisclosureNoticePayerLengthRule(maxLength: 120),
            ]
        )
    }
}
