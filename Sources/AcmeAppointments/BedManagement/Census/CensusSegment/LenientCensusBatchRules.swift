import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient census batch must pass. Check returns its problems, or none.
    protocol LenientCensusBatchRule {
        func check(_ item: LenientCensusBatch) -> [String]
    }

    final class LenientCensusBatchCurrencyLengthRule: LenientCensusBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCensusBatch) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCensusBatchChannelLengthRule: LenientCensusBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCensusBatch) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCensusBatchApprovedGuardRule: LenientCensusBatchRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LenientCensusBatch) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class LenientCensusBatchLimitRangeRule: LenientCensusBatchRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientCensusBatch) -> [String] {
            let value = item.limit
            var problems: [String] = []
            if value < min {
                problems.append("limit \(value) is below \(min)")
            }
            if value > max {
                problems.append("limit \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientCensusBatchRequiredCurrencyRule: LenientCensusBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCensusBatch) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient census batch.
    final class LenientCensusBatchValidator {
        var rules: [any LenientCensusBatchRule]

        init(rules: [any LenientCensusBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCensusBatch) -> [String] {
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

        func requireValid(_ item: LenientCensusBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCensusBatch]) -> [String: [String]] {
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

    static func defaultLenientCensusBatchValidator() -> LenientCensusBatchValidator {
        return LenientCensusBatchValidator(
            rules: [
                LenientCensusBatchCurrencyLengthRule(maxLength: 3600),
                LenientCensusBatchChannelLengthRule(maxLength: 32),
                LenientCensusBatchApprovedGuardRule(limit: 1000),
                LenientCensusBatchLimitRangeRule(min: 16, max: 1000),
                LenientCensusBatchRequiredCurrencyRule(message: "lenient census batch needs a value"),
            ]
        )
    }
}
