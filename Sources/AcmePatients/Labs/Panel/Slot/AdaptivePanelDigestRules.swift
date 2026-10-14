import AcmePlatform
import Foundation

extension Labs {
    /// A rule a adaptive panel digest must pass. Check returns its problems, or none.
    protocol AdaptivePanelDigestRule {
        func check(_ item: AdaptivePanelDigest) -> [String]
    }

    final class AdaptivePanelDigestCodeLengthRule: AdaptivePanelDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePanelDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePanelDigestTitleLengthRule: AdaptivePanelDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptivePanelDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptivePanelDigestAllowedTitleRule: AdaptivePanelDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptivePanelDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is too long"]
            }
            return []
        }
    }

    final class AdaptivePanelDigestRequiredTitleRule: AdaptivePanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelDigest) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePanelDigestRequiredPhoneRule: AdaptivePanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelDigest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePanelDigestRequiredCodeRule: AdaptivePanelDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePanelDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive panel digest.
    final class AdaptivePanelDigestValidator {
        var rules: [any AdaptivePanelDigestRule]

        init(rules: [any AdaptivePanelDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePanelDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptivePanelDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePanelDigest]) -> [String: [String]] {
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

    static func defaultAdaptivePanelDigestValidator() -> AdaptivePanelDigestValidator {
        return AdaptivePanelDigestValidator(
            rules: [
                AdaptivePanelDigestCodeLengthRule(maxLength: 120),
                AdaptivePanelDigestTitleLengthRule(maxLength: 3600),
                AdaptivePanelDigestAllowedTitleRule(allowed: ["weighted", "seasonal", "capped"]),
                AdaptivePanelDigestRequiredTitleRule(message: "adaptive panel digest needs a value"),
                AdaptivePanelDigestRequiredPhoneRule(message: "adaptive panel digest needs an entry"),
                AdaptivePanelDigestRequiredCodeRule(message: "adaptive panel digest needs an entry"),
            ]
        )
    }
}
