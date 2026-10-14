import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form cycle must pass. Check returns its problems, or none.
    protocol ConsentFormCycleRule {
        func check(_ item: ConsentFormCycle) -> [String]
    }

    final class ConsentFormCycleVisitMinutesRangeRule: ConsentFormCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ConsentFormCycle) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ConsentFormCycleApprovedGuardRule: ConsentFormCycleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ConsentFormCycle) -> [String] {
            if item.approved && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class ConsentFormCyclePayerLengthRule: ConsentFormCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormCycle) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form cycle.
    final class ConsentFormCycleValidator {
        var rules: [any ConsentFormCycleRule]

        init(rules: [any ConsentFormCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormCycle]) -> [String: [String]] {
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

    static func defaultConsentFormCycleValidator() -> ConsentFormCycleValidator {
        return ConsentFormCycleValidator(
            rules: [
                ConsentFormCycleVisitMinutesRangeRule(min: 255, max: 1000),
                ConsentFormCycleApprovedGuardRule(limit: 86400),
                ConsentFormCyclePayerLengthRule(maxLength: 16),
            ]
        )
    }
}
