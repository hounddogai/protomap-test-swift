import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol digest must pass. Check returns its problems, or none.
    protocol CareProtocolDigestRule {
        func check(_ item: CareProtocolDigest) -> [String]
    }

    final class CareProtocolDigestAllowedSourceRule: CareProtocolDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.source)) {
                return ["source \(item.source) is duplicated"]
            }
            return []
        }
    }

    final class CareProtocolDigestCodePrefixRule: CareProtocolDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolDigestRequiredCodeRule: CareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolDigestCodeLengthRule: CareProtocolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolDigestCreatedAtRangeRule: CareProtocolDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolDigest) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care protocol digest.
    final class CareProtocolDigestValidator {
        var rules: [any CareProtocolDigestRule]

        init(rules: [any CareProtocolDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolDigest]) -> [String: [String]] {
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

    static func defaultCareProtocolDigestValidator() -> CareProtocolDigestValidator {
        return CareProtocolDigestValidator(
            rules: [
                CareProtocolDigestAllowedSourceRule(allowed: ["rolling", "manual", "pending"]),
                CareProtocolDigestCodePrefixRule(prefix: "OPS"),
                CareProtocolDigestRequiredCodeRule(message: "care protocol digest needs this field"),
                CareProtocolDigestCodeLengthRule(maxLength: 80),
                CareProtocolDigestCreatedAtRangeRule(min: 32, max: 255),
            ]
        )
    }
}
