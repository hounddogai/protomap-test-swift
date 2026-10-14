import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled care protocol profile must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolProfileRule {
        func check(_ item: ScheduledCareProtocolProfile) -> [String]
    }

    final class ScheduledCareProtocolProfileRateRangeRule: ScheduledCareProtocolProfileRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledCareProtocolProfileRegionLengthRule: ScheduledCareProtocolProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolProfileRequiredCodeRule: ScheduledCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolProfileRequiredNameRule: ScheduledCareProtocolProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolProfile) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol profile.
    final class ScheduledCareProtocolProfileValidator {
        var rules: [any ScheduledCareProtocolProfileRule]

        init(rules: [any ScheduledCareProtocolProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareProtocolProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolProfile]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolProfileValidator() -> ScheduledCareProtocolProfileValidator {
        return ScheduledCareProtocolProfileValidator(
            rules: [
                ScheduledCareProtocolProfileRateRangeRule(min: 7.5, max: 772.0),
                ScheduledCareProtocolProfileRegionLengthRule(maxLength: 3600),
                ScheduledCareProtocolProfileRequiredCodeRule(
                    message: "scheduled care protocol profile needs this field"
                ),
                ScheduledCareProtocolProfileRequiredNameRule(
                    message: "scheduled care protocol profile needs this field"
                ),
            ]
        )
    }
}
