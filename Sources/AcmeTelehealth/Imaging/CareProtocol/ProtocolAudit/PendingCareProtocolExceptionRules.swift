import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a pending care protocol exception must pass. Check returns its problems, or none.
    protocol PendingCareProtocolExceptionRule {
        func check(_ item: PendingCareProtocolException) -> [String]
    }

    final class PendingCareProtocolExceptionCodeLengthRule: PendingCareProtocolExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingCareProtocolException) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingCareProtocolExceptionAllowedCodeRule: PendingCareProtocolExceptionRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingCareProtocolException) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is above maximum"]
            }
            return []
        }
    }

    final class PendingCareProtocolExceptionRequiredFacilityRule: PendingCareProtocolExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareProtocolException) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingCareProtocolExceptionRequiredNameRule: PendingCareProtocolExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingCareProtocolException) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending care protocol exception.
    final class PendingCareProtocolExceptionValidator {
        var rules: [any PendingCareProtocolExceptionRule]

        init(rules: [any PendingCareProtocolExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingCareProtocolException) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingCareProtocolException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingCareProtocolException]) -> [String: [String]] {
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

    static func defaultPendingCareProtocolExceptionValidator() -> PendingCareProtocolExceptionValidator {
        return PendingCareProtocolExceptionValidator(
            rules: [
                PendingCareProtocolExceptionCodeLengthRule(maxLength: 32),
                PendingCareProtocolExceptionAllowedCodeRule(allowed: ["strict", "weighted"]),
                PendingCareProtocolExceptionRequiredFacilityRule(
                    message: "pending care protocol exception needs an entry"
                ),
                PendingCareProtocolExceptionRequiredNameRule(
                    message: "pending care protocol exception needs an entry"
                ),
            ]
        )
    }
}
