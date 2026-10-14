import AcmePlatform
import Foundation

extension Consent {
    /// A rule a weighted consent form rollup must pass. Check returns its problems, or none.
    protocol WeightedConsentFormRollupRule {
        func check(_ item: WeightedConsentFormRollup) -> [String]
    }

    final class WeightedConsentFormRollupDurationMinutesRangeRule: WeightedConsentFormRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedConsentFormRollup) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedConsentFormRollupChannelLengthRule: WeightedConsentFormRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedConsentFormRollup) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedConsentFormRollupRegionLengthRule: WeightedConsentFormRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedConsentFormRollup) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedConsentFormRollupRequiredCodeRule: WeightedConsentFormRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedConsentFormRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted consent form rollup.
    final class WeightedConsentFormRollupValidator {
        var rules: [any WeightedConsentFormRollupRule]

        init(rules: [any WeightedConsentFormRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedConsentFormRollup) -> [String] {
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

        func requireValid(_ item: WeightedConsentFormRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedConsentFormRollup]) -> [String: [String]] {
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

    static func defaultWeightedConsentFormRollupValidator() -> WeightedConsentFormRollupValidator {
        return WeightedConsentFormRollupValidator(
            rules: [
                WeightedConsentFormRollupDurationMinutesRangeRule(min: 255, max: 86400),
                WeightedConsentFormRollupChannelLengthRule(maxLength: 64),
                WeightedConsentFormRollupRegionLengthRule(maxLength: 120),
                WeightedConsentFormRollupRequiredCodeRule(message: "weighted consent form rollup needs this field"),
            ]
        )
    }
}
