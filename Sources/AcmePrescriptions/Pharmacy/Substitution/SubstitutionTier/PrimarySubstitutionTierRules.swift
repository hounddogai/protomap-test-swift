import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a primary substitution tier must pass. Check returns its problems, or none.
    protocol PrimarySubstitutionTierRule {
        func check(_ item: PrimarySubstitutionTier) -> [String]
    }

    final class PrimarySubstitutionTierCodeLengthRule: PrimarySubstitutionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySubstitutionTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySubstitutionTierLabelLengthRule: PrimarySubstitutionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySubstitutionTier) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimarySubstitutionTierApprovedGuardRule: PrimarySubstitutionTierRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PrimarySubstitutionTier) -> [String] {
            if item.approved && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class PrimarySubstitutionTierSegmentLengthRule: PrimarySubstitutionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimarySubstitutionTier) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary substitution tier.
    final class PrimarySubstitutionTierValidator {
        var rules: [any PrimarySubstitutionTierRule]

        init(rules: [any PrimarySubstitutionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimarySubstitutionTier) -> [String] {
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

        func requireValid(_ item: PrimarySubstitutionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimarySubstitutionTier]) -> [String: [String]] {
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

    static func defaultPrimarySubstitutionTierValidator() -> PrimarySubstitutionTierValidator {
        return PrimarySubstitutionTierValidator(
            rules: [
                PrimarySubstitutionTierCodeLengthRule(maxLength: 80),
                PrimarySubstitutionTierLabelLengthRule(maxLength: 64),
                PrimarySubstitutionTierApprovedGuardRule(limit: 16),
                PrimarySubstitutionTierSegmentLengthRule(maxLength: 3600),
            ]
        )
    }
}
