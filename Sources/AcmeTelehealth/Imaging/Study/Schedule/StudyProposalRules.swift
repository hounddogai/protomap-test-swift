import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study proposal must pass. Check returns its problems, or none.
    protocol StudyProposalRule {
        func check(_ item: StudyProposal) -> [String]
    }

    final class StudyProposalRequiredCodeRule: StudyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyProposal) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudyProposalOwnerIDLengthRule: StudyProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyProposal) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyProposalMinimumRangeRule: StudyProposalRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudyProposal) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StudyProposalCodeLengthRule: StudyProposalRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudyProposal) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudyProposalAllowedOwnerIDRule: StudyProposalRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StudyProposal) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is above maximum"]
            }
            return []
        }
    }

    final class StudyProposalRequiredOwnerIDRule: StudyProposalRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudyProposal) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a study proposal.
    final class StudyProposalValidator {
        var rules: [any StudyProposalRule]

        init(rules: [any StudyProposalRule]) {
            self.rules = rules
        }

        func validate(_ item: StudyProposal) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StudyProposal) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudyProposal]) -> [String: [String]] {
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

    static func defaultStudyProposalValidator() -> StudyProposalValidator {
        return StudyProposalValidator(
            rules: [
                StudyProposalRequiredCodeRule(message: "study proposal needs this field"),
                StudyProposalOwnerIDLengthRule(maxLength: 255),
                StudyProposalMinimumRangeRule(min: 1.2, max: 4299.3),
                StudyProposalCodeLengthRule(maxLength: 3600),
                StudyProposalAllowedOwnerIDRule(allowed: ["adaptive", "lenient"]),
                StudyProposalRequiredOwnerIDRule(message: "study proposal needs a value"),
            ]
        )
    }
}
