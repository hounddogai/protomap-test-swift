import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary order set digest must pass. Check returns its problems, or none.
    protocol PrimaryOrderSetDigestRule {
        func check(_ item: PrimaryOrderSetDigest) -> [String]
    }

    final class PrimaryOrderSetDigestCapacityRangeRule: PrimaryOrderSetDigestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOrderSetDigest) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PrimaryOrderSetDigestCodePrefixRule: PrimaryOrderSetDigestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryOrderSetDigest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetDigestContactEmailLengthRule: PrimaryOrderSetDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOrderSetDigest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetDigestNameLengthRule: PrimaryOrderSetDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryOrderSetDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryOrderSetDigestArchivedGuardRule: PrimaryOrderSetDigestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: PrimaryOrderSetDigest) -> [String] {
            if item.archived && (item.budget > limit) {
                return ["budget \(item.budget) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class PrimaryOrderSetDigestMaximumRangeRule: PrimaryOrderSetDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryOrderSetDigest) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary order set digest.
    final class PrimaryOrderSetDigestValidator {
        var rules: [any PrimaryOrderSetDigestRule]

        init(rules: [any PrimaryOrderSetDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryOrderSetDigest) -> [String] {
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

        func requireValid(_ item: PrimaryOrderSetDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryOrderSetDigest]) -> [String: [String]] {
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

    static func defaultPrimaryOrderSetDigestValidator() -> PrimaryOrderSetDigestValidator {
        return PrimaryOrderSetDigestValidator(
            rules: [
                PrimaryOrderSetDigestCapacityRangeRule(min: 120, max: 86400),
                PrimaryOrderSetDigestCodePrefixRule(prefix: "Q"),
                PrimaryOrderSetDigestContactEmailLengthRule(maxLength: 86400),
                PrimaryOrderSetDigestNameLengthRule(maxLength: 16),
                PrimaryOrderSetDigestArchivedGuardRule(limit: 0.6),
                PrimaryOrderSetDigestMaximumRangeRule(min: 8.8, max: 3185.9),
            ]
        )
    }
}
