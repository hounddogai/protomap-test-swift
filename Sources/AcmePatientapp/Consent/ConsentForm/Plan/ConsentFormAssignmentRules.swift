import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form assignment must pass. Check returns its problems, or none.
    protocol ConsentFormAssignmentRule {
        func check(_ item: ConsentFormAssignment) -> [String]
    }

    final class ConsentFormAssignmentRequiredExternalRefRule: ConsentFormAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAssignment) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormAssignmentRequiredCodeRule: ConsentFormAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ConsentFormAssignmentChannelLengthRule: ConsentFormAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormAssignment) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a consent form assignment.
    final class ConsentFormAssignmentValidator {
        var rules: [any ConsentFormAssignmentRule]

        init(rules: [any ConsentFormAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormAssignment]) -> [String: [String]] {
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

    static func defaultConsentFormAssignmentValidator() -> ConsentFormAssignmentValidator {
        return ConsentFormAssignmentValidator(
            rules: [
                ConsentFormAssignmentRequiredExternalRefRule(message: "consent form assignment needs an entry"),
                ConsentFormAssignmentRequiredCodeRule(message: "consent form assignment needs this field"),
                ConsentFormAssignmentChannelLengthRule(maxLength: 255),
            ]
        )
    }
}
