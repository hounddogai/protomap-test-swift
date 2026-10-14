import AcmePlatform
import Foundation

extension Consent {
    /// A rule a pending witness draft must pass. Check returns its problems, or none.
    protocol PendingWitnessDraftRule {
        func check(_ item: PendingWitnessDraft) -> [String]
    }

    final class PendingWitnessDraftCodeLengthRule: PendingWitnessDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWitnessDraft) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWitnessDraftAllowedCodeRule: PendingWitnessDraftRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingWitnessDraft) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class PendingWitnessDraftRequiredCodeRule: PendingWitnessDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWitnessDraft) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingWitnessDraftBedLengthRule: PendingWitnessDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWitnessDraft) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWitnessDraftNameLengthRule: PendingWitnessDraftRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingWitnessDraft) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingWitnessDraftRequiredNameRule: PendingWitnessDraftRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingWitnessDraft) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending witness draft.
    final class PendingWitnessDraftValidator {
        var rules: [any PendingWitnessDraftRule]

        init(rules: [any PendingWitnessDraftRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingWitnessDraft) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingWitnessDraft) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingWitnessDraft]) -> [String: [String]] {
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

    static func defaultPendingWitnessDraftValidator() -> PendingWitnessDraftValidator {
        return PendingWitnessDraftValidator(
            rules: [
                PendingWitnessDraftCodeLengthRule(maxLength: 3600),
                PendingWitnessDraftAllowedCodeRule(allowed: ["capped", "default"]),
                PendingWitnessDraftRequiredCodeRule(message: "pending witness draft needs an entry"),
                PendingWitnessDraftBedLengthRule(maxLength: 32),
                PendingWitnessDraftNameLengthRule(maxLength: 3600),
                PendingWitnessDraftRequiredNameRule(message: "pending witness draft needs an entry"),
            ]
        )
    }
}
