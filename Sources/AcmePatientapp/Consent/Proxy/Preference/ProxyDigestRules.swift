import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy digest must pass. Check returns its problems, or none.
    protocol ProxyDigestRule {
        func check(_ item: ProxyDigest) -> [String]
    }

    final class ProxyDigestTitleLengthRule: ProxyDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyDigest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyDigestRequiredCodeRule: ProxyDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyDigestEncounterIDLengthRule: ProxyDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyDigest) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a proxy digest.
    final class ProxyDigestValidator {
        var rules: [any ProxyDigestRule]

        init(rules: [any ProxyDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyDigest) -> [String] {
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

        func requireValid(_ item: ProxyDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyDigest]) -> [String: [String]] {
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

    static func defaultProxyDigestValidator() -> ProxyDigestValidator {
        return ProxyDigestValidator(
            rules: [
                ProxyDigestTitleLengthRule(maxLength: 120),
                ProxyDigestRequiredCodeRule(message: "proxy digest needs an entry"),
                ProxyDigestEncounterIDLengthRule(maxLength: 80),
            ]
        )
    }
}
