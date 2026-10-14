import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation profile must pass. Check returns its problems, or none.
    protocol RevocationProfileRule {
        func check(_ item: RevocationProfile) -> [String]
    }

    final class RevocationProfileRequiredCodeRule: RevocationProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationProfileUpdatedAtRangeRule: RevocationProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationProfile) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationProfileNotesLengthRule: RevocationProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationProfile) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationProfilePhoneLengthRule: RevocationProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationProfile) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationProfileCodeLengthRule: RevocationProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationProfileTitleLengthRule: RevocationProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation profile.
    final class RevocationProfileValidator {
        var rules: [any RevocationProfileRule]

        init(rules: [any RevocationProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationProfile]) -> [String: [String]] {
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

    static func defaultRevocationProfileValidator() -> RevocationProfileValidator {
        return RevocationProfileValidator(
            rules: [
                RevocationProfileRequiredCodeRule(message: "revocation profile needs an entry"),
                RevocationProfileUpdatedAtRangeRule(min: 3600, max: 3600),
                RevocationProfileNotesLengthRule(maxLength: 86400),
                RevocationProfilePhoneLengthRule(maxLength: 3600),
                RevocationProfileCodeLengthRule(maxLength: 1000),
                RevocationProfileTitleLengthRule(maxLength: 255),
            ]
        )
    }
}
