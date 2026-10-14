import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction digest must pass. Check returns its problems, or none.
    protocol InteractionDigestRule {
        func check(_ item: InteractionDigest) -> [String]
    }

    final class InteractionDigestRequiredLabelRule: InteractionDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionDigest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionDigestBedLengthRule: InteractionDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionDigest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionDigestAllowedCodeRule: InteractionDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction digest.
    final class InteractionDigestValidator {
        var rules: [any InteractionDigestRule]

        init(rules: [any InteractionDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionDigest]) -> [String: [String]] {
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

    static func defaultInteractionDigestValidator() -> InteractionDigestValidator {
        return InteractionDigestValidator(
            rules: [
                InteractionDigestRequiredLabelRule(message: "interaction digest needs a value"),
                InteractionDigestBedLengthRule(maxLength: 3600),
                InteractionDigestAllowedCodeRule(allowed: ["rolling", "batched", "default"]),
            ]
        )
    }
}
