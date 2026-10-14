import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a seasonal cleaning manifest must pass. Check returns its problems, or none.
    protocol SeasonalCleaningManifestRule {
        func check(_ item: SeasonalCleaningManifest) -> [String]
    }

    final class SeasonalCleaningManifestCreatedAtRangeRule: SeasonalCleaningManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCleaningManifest) -> [String] {
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

    final class SeasonalCleaningManifestWeightRangeRule: SeasonalCleaningManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalCleaningManifest) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalCleaningManifestChecksumLengthRule: SeasonalCleaningManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCleaningManifest) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCleaningManifestAllowedChecksumRule: SeasonalCleaningManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalCleaningManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is stale"]
            }
            return []
        }
    }

    final class SeasonalCleaningManifestCodeLengthRule: SeasonalCleaningManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalCleaningManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalCleaningManifestRequiredNameRule: SeasonalCleaningManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalCleaningManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal cleaning manifest.
    final class SeasonalCleaningManifestValidator {
        var rules: [any SeasonalCleaningManifestRule]

        init(rules: [any SeasonalCleaningManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalCleaningManifest) -> [String] {
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

        func requireValid(_ item: SeasonalCleaningManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalCleaningManifest]) -> [String: [String]] {
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

    static func defaultSeasonalCleaningManifestValidator() -> SeasonalCleaningManifestValidator {
        return SeasonalCleaningManifestValidator(
            rules: [
                SeasonalCleaningManifestCreatedAtRangeRule(min: 255, max: 255),
                SeasonalCleaningManifestWeightRangeRule(min: 7.4, max: 1181.6),
                SeasonalCleaningManifestChecksumLengthRule(maxLength: 120),
                SeasonalCleaningManifestAllowedChecksumRule(allowed: []),
                SeasonalCleaningManifestCodeLengthRule(maxLength: 16),
                SeasonalCleaningManifestRequiredNameRule(message: "seasonal cleaning manifest needs this field"),
            ]
        )
    }
}
