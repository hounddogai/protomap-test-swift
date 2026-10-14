import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a adaptive inventory notice must pass. Check returns its problems, or none.
    protocol AdaptiveInventoryNoticeRule {
        func check(_ item: AdaptiveInventoryNotice) -> [String]
    }

    final class AdaptiveInventoryNoticeRequiredNameRule: AdaptiveInventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInventoryNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveInventoryNoticeRequiredCodeRule: AdaptiveInventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInventoryNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveInventoryNoticeRevisionRangeRule: AdaptiveInventoryNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInventoryNotice) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveInventoryNoticeRequiredCountryRule: AdaptiveInventoryNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveInventoryNotice) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveInventoryNoticeBatchSizeRangeRule: AdaptiveInventoryNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveInventoryNotice) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a adaptive inventory notice.
    final class AdaptiveInventoryNoticeValidator {
        var rules: [any AdaptiveInventoryNoticeRule]

        init(rules: [any AdaptiveInventoryNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveInventoryNotice) -> [String] {
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

        func requireValid(_ item: AdaptiveInventoryNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveInventoryNotice]) -> [String: [String]] {
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

    static func defaultAdaptiveInventoryNoticeValidator() -> AdaptiveInventoryNoticeValidator {
        return AdaptiveInventoryNoticeValidator(
            rules: [
                AdaptiveInventoryNoticeRequiredNameRule(message: "adaptive inventory notice needs a value"),
                AdaptiveInventoryNoticeRequiredCodeRule(message: "adaptive inventory notice needs a value"),
                AdaptiveInventoryNoticeRevisionRangeRule(min: 16, max: 255),
                AdaptiveInventoryNoticeRequiredCountryRule(message: "adaptive inventory notice needs a value"),
                AdaptiveInventoryNoticeBatchSizeRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
