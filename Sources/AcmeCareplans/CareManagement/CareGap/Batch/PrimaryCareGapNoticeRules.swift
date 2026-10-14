import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a primary care gap notice must pass. Check returns its problems, or none.
    protocol PrimaryCareGapNoticeRule {
        func check(_ item: PrimaryCareGapNotice) -> [String]
    }

    final class PrimaryCareGapNoticeRequiredNameRule: PrimaryCareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareGapNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareGapNoticeCodePrefixRule: PrimaryCareGapNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryCareGapNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryCareGapNoticeRequiredCodeRule: PrimaryCareGapNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCareGapNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryCareGapNoticeEndsAtRangeRule: PrimaryCareGapNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCareGapNotice) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary care gap notice.
    final class PrimaryCareGapNoticeValidator {
        var rules: [any PrimaryCareGapNoticeRule]

        init(rules: [any PrimaryCareGapNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCareGapNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryCareGapNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCareGapNotice]) -> [String: [String]] {
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

    static func defaultPrimaryCareGapNoticeValidator() -> PrimaryCareGapNoticeValidator {
        return PrimaryCareGapNoticeValidator(
            rules: [
                PrimaryCareGapNoticeRequiredNameRule(message: "primary care gap notice needs an entry"),
                PrimaryCareGapNoticeCodePrefixRule(prefix: "REF"),
                PrimaryCareGapNoticeRequiredCodeRule(message: "primary care gap notice needs an entry"),
                PrimaryCareGapNoticeEndsAtRangeRule(min: 16, max: 64),
            ]
        )
    }
}
