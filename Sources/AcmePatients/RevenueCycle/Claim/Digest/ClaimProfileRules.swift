import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim profile must pass. Check returns its problems, or none.
    protocol ClaimProfileRule {
        func check(_ item: ClaimProfile) -> [String]
    }

    final class ClaimProfileDescriptionLengthRule: ClaimProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimProfile) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimProfileRequiredSegmentRule: ClaimProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimProfile) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimProfileVisitMinutesRangeRule: ClaimProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimProfile) -> [String] {
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

    final class ClaimProfileRequiredCodeRule: ClaimProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim profile.
    final class ClaimProfileValidator {
        var rules: [any ClaimProfileRule]

        init(rules: [any ClaimProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimProfile) -> [String] {
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

        func requireValid(_ item: ClaimProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimProfile]) -> [String: [String]] {
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

    static func defaultClaimProfileValidator() -> ClaimProfileValidator {
        return ClaimProfileValidator(
            rules: [
                ClaimProfileDescriptionLengthRule(maxLength: 255),
                ClaimProfileRequiredSegmentRule(message: "claim profile needs a value"),
                ClaimProfileVisitMinutesRangeRule(min: 80, max: 86400),
                ClaimProfileRequiredCodeRule(message: "claim profile needs this field"),
            ]
        )
    }
}
