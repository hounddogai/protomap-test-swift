import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled care protocol exception must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolExceptionRule {
        func check(_ item: ScheduledCareProtocolException) -> [String]
    }

    final class ScheduledCareProtocolExceptionEncounterIDLengthRule: ScheduledCareProtocolExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolException) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolExceptionRegionLengthRule: ScheduledCareProtocolExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolException) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolExceptionRequiredRegionRule: ScheduledCareProtocolExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolException) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolExceptionAllowedChannelRule: ScheduledCareProtocolExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCareProtocolException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is above maximum"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol exception.
    final class ScheduledCareProtocolExceptionValidator {
        var rules: [any ScheduledCareProtocolExceptionRule]

        init(rules: [any ScheduledCareProtocolExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCareProtocolException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolException]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolExceptionValidator() -> ScheduledCareProtocolExceptionValidator {
        return ScheduledCareProtocolExceptionValidator(
            rules: [
                ScheduledCareProtocolExceptionEncounterIDLengthRule(maxLength: 80),
                ScheduledCareProtocolExceptionRegionLengthRule(maxLength: 80),
                ScheduledCareProtocolExceptionRequiredRegionRule(
                    message: "scheduled care protocol exception needs this field"
                ),
                ScheduledCareProtocolExceptionAllowedChannelRule(allowed: ["batched"]),
            ]
        )
    }
}
