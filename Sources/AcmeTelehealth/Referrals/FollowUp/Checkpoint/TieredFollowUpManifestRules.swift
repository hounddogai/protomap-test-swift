import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a tiered follow up manifest must pass. Check returns its problems, or none.
    protocol TieredFollowUpManifestRule {
        func check(_ item: TieredFollowUpManifest) -> [String]
    }

    final class TieredFollowUpManifestDiscountRangeRule: TieredFollowUpManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredFollowUpManifest) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredFollowUpManifestRequiredLabelRule: TieredFollowUpManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFollowUpManifestApprovedGuardRule: TieredFollowUpManifestRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredFollowUpManifest) -> [String] {
            if item.approved && (item.discount > limit) {
                return ["discount \(item.discount) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredFollowUpManifestRequiredCodeRule: TieredFollowUpManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredFollowUpManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredFollowUpManifestContactEmailLengthRule: TieredFollowUpManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredFollowUpManifest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredFollowUpManifestCodePrefixRule: TieredFollowUpManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredFollowUpManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered follow up manifest.
    final class TieredFollowUpManifestValidator {
        var rules: [any TieredFollowUpManifestRule]

        init(rules: [any TieredFollowUpManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredFollowUpManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredFollowUpManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredFollowUpManifest]) -> [String: [String]] {
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

    static func defaultTieredFollowUpManifestValidator() -> TieredFollowUpManifestValidator {
        return TieredFollowUpManifestValidator(
            rules: [
                TieredFollowUpManifestDiscountRangeRule(min: 4.1, max: 806.0),
                TieredFollowUpManifestRequiredLabelRule(message: "tiered follow up manifest needs this field"),
                TieredFollowUpManifestApprovedGuardRule(limit: 5.7),
                TieredFollowUpManifestRequiredCodeRule(message: "tiered follow up manifest needs this field"),
                TieredFollowUpManifestContactEmailLengthRule(maxLength: 16),
                TieredFollowUpManifestCodePrefixRule(prefix: "REF"),
            ]
        )
    }
}
