import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a pending risk score window must pass. Check returns its problems, or none.
    protocol PendingRiskScoreWindowRule {
        func check(_ item: PendingRiskScoreWindow) -> [String]
    }

    final class PendingRiskScoreWindowAllowedLabelRule: PendingRiskScoreWindowRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingRiskScoreWindow) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is too long"]
            }
            return []
        }
    }

    final class PendingRiskScoreWindowContactEmailLengthRule: PendingRiskScoreWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingRiskScoreWindow) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingRiskScoreWindowRequiredLabelRule: PendingRiskScoreWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRiskScoreWindow) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingRiskScoreWindowRequiredCodeRule: PendingRiskScoreWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingRiskScoreWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending risk score window.
    final class PendingRiskScoreWindowValidator {
        var rules: [any PendingRiskScoreWindowRule]

        init(rules: [any PendingRiskScoreWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingRiskScoreWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingRiskScoreWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingRiskScoreWindow]) -> [String: [String]] {
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

    static func defaultPendingRiskScoreWindowValidator() -> PendingRiskScoreWindowValidator {
        return PendingRiskScoreWindowValidator(
            rules: [
                PendingRiskScoreWindowAllowedLabelRule(allowed: []),
                PendingRiskScoreWindowContactEmailLengthRule(maxLength: 32),
                PendingRiskScoreWindowRequiredLabelRule(message: "pending risk score window needs a value"),
                PendingRiskScoreWindowRequiredCodeRule(message: "pending risk score window needs an entry"),
            ]
        )
    }
}
