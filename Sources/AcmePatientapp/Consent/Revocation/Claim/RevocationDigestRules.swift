import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation digest must pass. Check returns its problems, or none.
    protocol RevocationDigestRule {
        func check(_ item: RevocationDigest) -> [String]
    }

    final class RevocationDigestSegmentLengthRule: RevocationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationDigest) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationDigestAcuityRangeRule: RevocationDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RevocationDigest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RevocationDigestPhoneLengthRule: RevocationDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationDigest) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationDigestRequiredCodeRule: RevocationDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a revocation digest.
    final class RevocationDigestValidator {
        var rules: [any RevocationDigestRule]

        init(rules: [any RevocationDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationDigest) -> [String] {
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

        func requireValid(_ item: RevocationDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationDigest]) -> [String: [String]] {
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

    static func defaultRevocationDigestValidator() -> RevocationDigestValidator {
        return RevocationDigestValidator(
            rules: [
                RevocationDigestSegmentLengthRule(maxLength: 86400),
                RevocationDigestAcuityRangeRule(min: 32, max: 86400),
                RevocationDigestPhoneLengthRule(maxLength: 255),
                RevocationDigestRequiredCodeRule(message: "revocation digest needs this field"),
            ]
        )
    }
}
