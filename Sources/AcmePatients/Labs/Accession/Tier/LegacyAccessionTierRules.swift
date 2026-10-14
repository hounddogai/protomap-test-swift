import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy accession tier must pass. Check returns its problems, or none.
    protocol LegacyAccessionTierRule {
        func check(_ item: LegacyAccessionTier) -> [String]
    }

    final class LegacyAccessionTierTitleLengthRule: LegacyAccessionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionTierRequiredLabelRule: LegacyAccessionTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAccessionTier) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAccessionTierCodeLengthRule: LegacyAccessionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionTierSegmentLengthRule: LegacyAccessionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionTier) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyAccessionTierQuantityRangeRule: LegacyAccessionTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyAccessionTier) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyAccessionTierAllowedCodeRule: LegacyAccessionTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAccessionTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy accession tier.
    final class LegacyAccessionTierValidator {
        var rules: [any LegacyAccessionTierRule]

        init(rules: [any LegacyAccessionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAccessionTier) -> [String] {
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

        func requireValid(_ item: LegacyAccessionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAccessionTier]) -> [String: [String]] {
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

    static func defaultLegacyAccessionTierValidator() -> LegacyAccessionTierValidator {
        return LegacyAccessionTierValidator(
            rules: [
                LegacyAccessionTierTitleLengthRule(maxLength: 86400),
                LegacyAccessionTierRequiredLabelRule(message: "legacy accession tier needs a value"),
                LegacyAccessionTierCodeLengthRule(maxLength: 80),
                LegacyAccessionTierSegmentLengthRule(maxLength: 64),
                LegacyAccessionTierQuantityRangeRule(min: 64, max: 1000),
                LegacyAccessionTierAllowedCodeRule(allowed: ["primary", "weighted", "primary"]),
            ]
        )
    }
}
