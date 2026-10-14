import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global follow up baseline must pass. Check returns its problems, or none.
    protocol GlobalFollowUpBaselineRule {
        func check(_ item: GlobalFollowUpBaseline) -> [String]
    }

    final class GlobalFollowUpBaselineRequiredCodeRule: GlobalFollowUpBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFollowUpBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFollowUpBaselineRequiredPatientRefRule: GlobalFollowUpBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalFollowUpBaseline) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalFollowUpBaselinePatientRefLengthRule: GlobalFollowUpBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalFollowUpBaseline) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalFollowUpBaselineCodePrefixRule: GlobalFollowUpBaselineRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalFollowUpBaseline) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalFollowUpBaselineDurationMinutesRangeRule: GlobalFollowUpBaselineRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalFollowUpBaseline) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global follow up baseline.
    final class GlobalFollowUpBaselineValidator {
        var rules: [any GlobalFollowUpBaselineRule]

        init(rules: [any GlobalFollowUpBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalFollowUpBaseline) -> [String] {
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

        func requireValid(_ item: GlobalFollowUpBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalFollowUpBaseline]) -> [String: [String]] {
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

    static func defaultGlobalFollowUpBaselineValidator() -> GlobalFollowUpBaselineValidator {
        return GlobalFollowUpBaselineValidator(
            rules: [
                GlobalFollowUpBaselineRequiredCodeRule(message: "global follow up baseline needs an entry"),
                GlobalFollowUpBaselineRequiredPatientRefRule(message: "global follow up baseline needs an entry"),
                GlobalFollowUpBaselinePatientRefLengthRule(maxLength: 3600),
                GlobalFollowUpBaselineCodePrefixRule(prefix: "OPS"),
                GlobalFollowUpBaselineDurationMinutesRangeRule(min: 64, max: 120),
            ]
        )
    }
}
