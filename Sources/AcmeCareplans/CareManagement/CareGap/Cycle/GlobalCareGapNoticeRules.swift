import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global care gap notice must pass. Check returns its problems, or none.
    protocol GlobalCareGapNoticeRule {
        func check(_ item: GlobalCareGapNotice) -> [String]
    }

    final class GlobalCareGapNoticeCodePrefixRule: GlobalCareGapNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalCareGapNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalCareGapNoticeMarginRangeRule: GlobalCareGapNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalCareGapNotice) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalCareGapNoticeNameLengthRule: GlobalCareGapNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareGapNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalCareGapNoticeArchivedGuardRule: GlobalCareGapNoticeRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: GlobalCareGapNotice) -> [String] {
            if item.archived && (item.margin > limit) {
                return ["margin \(item.margin) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class GlobalCareGapNoticeCodeLengthRule: GlobalCareGapNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalCareGapNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global care gap notice.
    final class GlobalCareGapNoticeValidator {
        var rules: [any GlobalCareGapNoticeRule]

        init(rules: [any GlobalCareGapNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalCareGapNotice) -> [String] {
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

        func requireValid(_ item: GlobalCareGapNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalCareGapNotice]) -> [String: [String]] {
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

    static func defaultGlobalCareGapNoticeValidator() -> GlobalCareGapNoticeValidator {
        return GlobalCareGapNoticeValidator(
            rules: [
                GlobalCareGapNoticeCodePrefixRule(prefix: "Q"),
                GlobalCareGapNoticeMarginRangeRule(min: 5.0, max: 3272.8),
                GlobalCareGapNoticeNameLengthRule(maxLength: 80),
                GlobalCareGapNoticeArchivedGuardRule(limit: 6.8),
                GlobalCareGapNoticeCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
