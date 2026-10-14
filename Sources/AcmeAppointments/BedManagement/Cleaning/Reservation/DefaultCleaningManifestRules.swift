import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a default cleaning manifest must pass. Check returns its problems, or none.
    protocol DefaultCleaningManifestRule {
        func check(_ item: DefaultCleaningManifest) -> [String]
    }

    final class DefaultCleaningManifestGraceDaysRangeRule: DefaultCleaningManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCleaningManifest) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCleaningManifestLabelLengthRule: DefaultCleaningManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultCleaningManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultCleaningManifestAllowedCodeRule: DefaultCleaningManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultCleaningManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class DefaultCleaningManifestCodePrefixRule: DefaultCleaningManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultCleaningManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultCleaningManifestBatchSizeRangeRule: DefaultCleaningManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCleaningManifest) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultCleaningManifestWindowDaysRangeRule: DefaultCleaningManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultCleaningManifest) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a default cleaning manifest.
    final class DefaultCleaningManifestValidator {
        var rules: [any DefaultCleaningManifestRule]

        init(rules: [any DefaultCleaningManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultCleaningManifest) -> [String] {
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

        func requireValid(_ item: DefaultCleaningManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultCleaningManifest]) -> [String: [String]] {
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

    static func defaultDefaultCleaningManifestValidator() -> DefaultCleaningManifestValidator {
        return DefaultCleaningManifestValidator(
            rules: [
                DefaultCleaningManifestGraceDaysRangeRule(min: 16, max: 120),
                DefaultCleaningManifestLabelLengthRule(maxLength: 255),
                DefaultCleaningManifestAllowedCodeRule(allowed: ["default", "weighted", "regional"]),
                DefaultCleaningManifestCodePrefixRule(prefix: "REF"),
                DefaultCleaningManifestBatchSizeRangeRule(min: 32, max: 1000),
                DefaultCleaningManifestWindowDaysRangeRule(min: 32, max: 255),
            ]
        )
    }
}
