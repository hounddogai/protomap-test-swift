import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach digest must pass. Check returns its problems, or none.
    protocol OutreachDigestRule {
        func check(_ item: OutreachDigest) -> [String]
    }

    final class OutreachDigestBatchSizeRangeRule: OutreachDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OutreachDigest) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OutreachDigestRequiredChecksumRule: OutreachDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachDigest) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachDigestAllowedPayerRule: OutreachDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OutreachDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a outreach digest.
    final class OutreachDigestValidator {
        var rules: [any OutreachDigestRule]

        init(rules: [any OutreachDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachDigest) -> [String] {
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

        func requireValid(_ item: OutreachDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachDigest]) -> [String: [String]] {
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

    static func defaultOutreachDigestValidator() -> OutreachDigestValidator {
        return OutreachDigestValidator(
            rules: [
                OutreachDigestBatchSizeRangeRule(min: 255, max: 1000),
                OutreachDigestRequiredChecksumRule(message: "outreach digest needs this field"),
                OutreachDigestAllowedPayerRule(allowed: ["legacy", "regional"]),
            ]
        )
    }
}
