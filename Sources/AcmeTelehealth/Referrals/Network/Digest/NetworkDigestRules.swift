import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a network digest must pass. Check returns its problems, or none.
    protocol NetworkDigestRule {
        func check(_ item: NetworkDigest) -> [String]
    }

    final class NetworkDigestNameLengthRule: NetworkDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkDigestBedLengthRule: NetworkDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkDigest) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkDigestRequiredNameRule: NetworkDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkDigest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class NetworkDigestCodeLengthRule: NetworkDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: NetworkDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class NetworkDigestRequiredCodeRule: NetworkDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: NetworkDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a network digest.
    final class NetworkDigestValidator {
        var rules: [any NetworkDigestRule]

        init(rules: [any NetworkDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: NetworkDigest) -> [String] {
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

        func requireValid(_ item: NetworkDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [NetworkDigest]) -> [String: [String]] {
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

    static func defaultNetworkDigestValidator() -> NetworkDigestValidator {
        return NetworkDigestValidator(
            rules: [
                NetworkDigestNameLengthRule(maxLength: 255),
                NetworkDigestBedLengthRule(maxLength: 3600),
                NetworkDigestRequiredNameRule(message: "network digest needs an entry"),
                NetworkDigestCodeLengthRule(maxLength: 3600),
                NetworkDigestRequiredCodeRule(message: "network digest needs a value"),
            ]
        )
    }
}
