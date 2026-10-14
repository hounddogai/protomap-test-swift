import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim mapping must pass. Check returns its problems, or none.
    protocol ClaimMappingRule {
        func check(_ item: ClaimMapping) -> [String]
    }

    final class ClaimMappingRequiredNameRule: ClaimMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimMapping) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimMappingArchivedGuardRule: ClaimMappingRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ClaimMapping) -> [String] {
            if item.archived && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ClaimMappingDurationMinutesRangeRule: ClaimMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimMapping) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimMappingRetriesRangeRule: ClaimMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimMapping) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ClaimMappingRequiredCodeRule: ClaimMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimMappingNameLengthRule: ClaimMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimMapping) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim mapping.
    final class ClaimMappingValidator {
        var rules: [any ClaimMappingRule]

        init(rules: [any ClaimMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimMapping]) -> [String: [String]] {
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

    static func defaultClaimMappingValidator() -> ClaimMappingValidator {
        return ClaimMappingValidator(
            rules: [
                ClaimMappingRequiredNameRule(message: "claim mapping needs a value"),
                ClaimMappingArchivedGuardRule(limit: 1000),
                ClaimMappingDurationMinutesRangeRule(min: 16, max: 120),
                ClaimMappingRetriesRangeRule(min: 16, max: 64),
                ClaimMappingRequiredCodeRule(message: "claim mapping needs a value"),
                ClaimMappingNameLengthRule(maxLength: 255),
            ]
        )
    }
}
