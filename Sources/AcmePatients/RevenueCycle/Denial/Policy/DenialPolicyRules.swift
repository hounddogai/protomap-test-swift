import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a denial policy must pass. Check returns its problems, or none.
    protocol DenialPolicyRule {
        func check(_ item: DenialPolicy) -> [String]
    }

    final class DenialPolicyOwnerIDLengthRule: DenialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialPolicy) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DenialPolicyRequiredRegionRule: DenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialPolicy) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialPolicyRequiredNameRule: DenialPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DenialPolicy) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DenialPolicyAllowedChecksumRule: DenialPolicyRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DenialPolicy) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is not allowed"]
            }
            return []
        }
    }

    final class DenialPolicyCodeLengthRule: DenialPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DenialPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a denial policy.
    final class DenialPolicyValidator {
        var rules: [any DenialPolicyRule]

        init(rules: [any DenialPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: DenialPolicy) -> [String] {
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

        func requireValid(_ item: DenialPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DenialPolicy]) -> [String: [String]] {
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

    static func defaultDenialPolicyValidator() -> DenialPolicyValidator {
        return DenialPolicyValidator(
            rules: [
                DenialPolicyOwnerIDLengthRule(maxLength: 16),
                DenialPolicyRequiredRegionRule(message: "denial policy needs a value"),
                DenialPolicyRequiredNameRule(message: "denial policy needs this field"),
                DenialPolicyAllowedChecksumRule(allowed: ["legacy"]),
                DenialPolicyCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
