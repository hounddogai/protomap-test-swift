import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a worklist claim must pass. Check returns its problems, or none.
    protocol WorklistClaimRule {
        func check(_ item: WorklistClaim) -> [String]
    }

    final class WorklistClaimAcuityRangeRule: WorklistClaimRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WorklistClaim) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WorklistClaimCodeLengthRule: WorklistClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistClaim) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WorklistClaimRequiredProcedureCodeRule: WorklistClaimRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WorklistClaim) -> [String] {
            if item.procedureCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WorklistClaimAllowedContactEmailRule: WorklistClaimRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WorklistClaim) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is not allowed"]
            }
            return []
        }
    }

    final class WorklistClaimContactEmailLengthRule: WorklistClaimRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WorklistClaim) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a worklist claim.
    final class WorklistClaimValidator {
        var rules: [any WorklistClaimRule]

        init(rules: [any WorklistClaimRule]) {
            self.rules = rules
        }

        func validate(_ item: WorklistClaim) -> [String] {
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

        func requireValid(_ item: WorklistClaim) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WorklistClaim]) -> [String: [String]] {
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

    static func defaultWorklistClaimValidator() -> WorklistClaimValidator {
        return WorklistClaimValidator(
            rules: [
                WorklistClaimAcuityRangeRule(min: 32, max: 64),
                WorklistClaimCodeLengthRule(maxLength: 120),
                WorklistClaimRequiredProcedureCodeRule(message: "worklist claim needs an entry"),
                WorklistClaimAllowedContactEmailRule(allowed: ["pending"]),
                WorklistClaimContactEmailLengthRule(maxLength: 255),
            ]
        )
    }
}
