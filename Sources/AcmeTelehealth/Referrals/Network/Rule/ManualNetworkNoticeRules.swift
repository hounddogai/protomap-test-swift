import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network notice must pass. Check returns its problems, or none.
    protocol ManualNetworkNoticeRule {
        func check(_ item: ManualNetworkNotice) -> [String]
    }

    final class ManualNetworkNoticeRateRangeRule: ManualNetworkNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkNotice) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualNetworkNoticeNameLengthRule: ManualNetworkNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkNoticeDiscountRangeRule: ManualNetworkNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkNotice) -> [String] {
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

    final class ManualNetworkNoticeCodeLengthRule: ManualNetworkNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualNetworkNoticeRatioRangeRule: ManualNetworkNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkNotice) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualNetworkNoticeActiveGuardRule: ManualNetworkNoticeRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ManualNetworkNotice) -> [String] {
            if item.active && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network notice.
    final class ManualNetworkNoticeValidator {
        var rules: [any ManualNetworkNoticeRule]

        init(rules: [any ManualNetworkNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkNotice) -> [String] {
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

        func requireValid(_ item: ManualNetworkNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkNotice]) -> [String: [String]] {
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

    static func defaultManualNetworkNoticeValidator() -> ManualNetworkNoticeValidator {
        return ManualNetworkNoticeValidator(
            rules: [
                ManualNetworkNoticeRateRangeRule(min: 5.4, max: 1206.1),
                ManualNetworkNoticeNameLengthRule(maxLength: 255),
                ManualNetworkNoticeDiscountRangeRule(min: 2.4, max: 59.3),
                ManualNetworkNoticeCodeLengthRule(maxLength: 120),
                ManualNetworkNoticeRatioRangeRule(min: 1.9, max: 1105.0),
                ManualNetworkNoticeActiveGuardRule(limit: 3.0),
            ]
        )
    }
}
