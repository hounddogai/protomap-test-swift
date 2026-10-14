import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure digest must pass. Check returns its problems, or none.
    protocol ClosureDigestRule {
        func check(_ item: ClosureDigest) -> [String]
    }

    final class ClosureDigestRetriesRangeRule: ClosureDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClosureDigest) -> [String] {
            let value = item.retries
            var problems: [String] = []
            if value < min {
                problems.append("retries \(value) is below \(min)")
            }
            if value > max {
                problems.append("retries \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClosureDigestRequiredCodeRule: ClosureDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureDigestCodeLengthRule: ClosureDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureDigestRequiredEncounterIDRule: ClosureDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureDigest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureDigestEncounterIDLengthRule: ClosureDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureDigest) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure digest.
    final class ClosureDigestValidator {
        var rules: [any ClosureDigestRule]

        init(rules: [any ClosureDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClosureDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureDigest]) -> [String: [String]] {
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

    static func defaultClosureDigestValidator() -> ClosureDigestValidator {
        return ClosureDigestValidator(
            rules: [
                ClosureDigestRetriesRangeRule(min: 1000, max: 3600),
                ClosureDigestRequiredCodeRule(message: "closure digest needs this field"),
                ClosureDigestCodeLengthRule(maxLength: 3600),
                ClosureDigestRequiredEncounterIDRule(message: "closure digest needs a value"),
                ClosureDigestEncounterIDLengthRule(maxLength: 32),
            ]
        )
    }
}
