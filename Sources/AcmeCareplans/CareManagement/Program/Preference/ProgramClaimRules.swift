import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program claim must pass. Check returns its problems, or none.
    protocol ProgramClaimRule {
        func check(_ item: ProgramClaim) -> [String]
    }

    final class ProgramClaimLabelLengthRule: ProgramClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramClaim) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramClaimAllowedSegmentRule: ProgramClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is duplicated"]
            }
            return []
        }
    }

    final class ProgramClaimRequiredLabelRule: ProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramClaim) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramClaimCodeLengthRule: ProgramClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramClaimRequiredCodeRule: ProgramClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramClaim) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a program claim.
    final class ProgramClaimValidator {
        var rules: [any ProgramClaimRule]

        init(rules: [any ProgramClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramClaim) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramClaim]) -> [String: [String]] {
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

    static func defaultProgramClaimValidator() -> ProgramClaimValidator {
        return ProgramClaimValidator(
            rules: [
                ProgramClaimLabelLengthRule(maxLength: 120),
                ProgramClaimAllowedSegmentRule(allowed: ["rolling", "batched"]),
                ProgramClaimRequiredLabelRule(message: "program claim needs an entry"),
                ProgramClaimCodeLengthRule(maxLength: 120),
                ProgramClaimRequiredCodeRule(message: "program claim needs an entry"),
            ]
        )
    }
}
