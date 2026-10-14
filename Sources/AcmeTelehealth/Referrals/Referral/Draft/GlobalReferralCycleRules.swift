import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a global referral cycle must pass. Check returns its problems, or none.
    protocol GlobalReferralCycleRule {
        func check(_ item: GlobalReferralCycle) -> [String]
    }

    final class GlobalReferralCycleRequiredPatientRefRule: GlobalReferralCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalReferralCycle) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalReferralCycleDurationMinutesRangeRule: GlobalReferralCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReferralCycle) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalReferralCycleCodePrefixRule: GlobalReferralCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalReferralCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalReferralCycleEndsAtRangeRule: GlobalReferralCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalReferralCycle) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalReferralCycleTitleLengthRule: GlobalReferralCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalReferralCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global referral cycle.
    final class GlobalReferralCycleValidator {
        var rules: [any GlobalReferralCycleRule]

        init(rules: [any GlobalReferralCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalReferralCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalReferralCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalReferralCycle]) -> [String: [String]] {
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

    static func defaultGlobalReferralCycleValidator() -> GlobalReferralCycleValidator {
        return GlobalReferralCycleValidator(
            rules: [
                GlobalReferralCycleRequiredPatientRefRule(message: "global referral cycle needs a value"),
                GlobalReferralCycleDurationMinutesRangeRule(min: 120, max: 1000),
                GlobalReferralCycleCodePrefixRule(prefix: "REF"),
                GlobalReferralCycleEndsAtRangeRule(min: 255, max: 1000),
                GlobalReferralCycleTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
