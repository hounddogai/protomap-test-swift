import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution segment must pass. Check returns its problems, or none.
    protocol SubstitutionSegmentRule {
        func check(_ item: SubstitutionSegment) -> [String]
    }

    final class SubstitutionSegmentExpiresAtRangeRule: SubstitutionSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionSegment) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SubstitutionSegmentAllowedChecksumRule: SubstitutionSegmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SubstitutionSegment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is not allowed"]
            }
            return []
        }
    }

    final class SubstitutionSegmentCodePrefixRule: SubstitutionSegmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SubstitutionSegment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SubstitutionSegmentLabelLengthRule: SubstitutionSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionSegment) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a substitution segment.
    final class SubstitutionSegmentValidator {
        var rules: [any SubstitutionSegmentRule]

        init(rules: [any SubstitutionSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionSegment) -> [String] {
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

        func requireValid(_ item: SubstitutionSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionSegment]) -> [String: [String]] {
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

    static func defaultSubstitutionSegmentValidator() -> SubstitutionSegmentValidator {
        return SubstitutionSegmentValidator(
            rules: [
                SubstitutionSegmentExpiresAtRangeRule(min: 120, max: 1000),
                SubstitutionSegmentAllowedChecksumRule(allowed: ["default"]),
                SubstitutionSegmentCodePrefixRule(prefix: "ACM"),
                SubstitutionSegmentLabelLengthRule(maxLength: 3600),
            ]
        )
    }
}
