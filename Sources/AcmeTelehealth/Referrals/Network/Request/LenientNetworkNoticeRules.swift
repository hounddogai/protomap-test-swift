import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient network notice must pass. Check returns its problems, or none.
    protocol LenientNetworkNoticeRule {
        func check(_ item: LenientNetworkNotice) -> [String]
    }

    final class LenientNetworkNoticeRequiredCodeRule: LenientNetworkNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientNetworkNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientNetworkNoticeRequiredTitleRule: LenientNetworkNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientNetworkNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientNetworkNoticeUpdatedAtRangeRule: LenientNetworkNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientNetworkNotice) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientNetworkNoticeRequiredUnitRule: LenientNetworkNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientNetworkNotice) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient network notice.
    final class LenientNetworkNoticeValidator {
        var rules: [any LenientNetworkNoticeRule]

        init(rules: [any LenientNetworkNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientNetworkNotice) -> [String] {
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

        func requireValid(_ item: LenientNetworkNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientNetworkNotice]) -> [String: [String]] {
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

    static func defaultLenientNetworkNoticeValidator() -> LenientNetworkNoticeValidator {
        return LenientNetworkNoticeValidator(
            rules: [
                LenientNetworkNoticeRequiredCodeRule(message: "lenient network notice needs a value"),
                LenientNetworkNoticeRequiredTitleRule(message: "lenient network notice needs a value"),
                LenientNetworkNoticeUpdatedAtRangeRule(min: 32, max: 1000),
                LenientNetworkNoticeRequiredUnitRule(message: "lenient network notice needs this field"),
            ]
        )
    }
}
