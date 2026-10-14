import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary cleaning manifest must pass. Check returns its problems, or none.
    protocol PrimaryCleaningManifestRule {
        func check(_ item: PrimaryCleaningManifest) -> [String]
    }

    final class PrimaryCleaningManifestTitleLengthRule: PrimaryCleaningManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCleaningManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCleaningManifestAllowedCodeRule: PrimaryCleaningManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryCleaningManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is too long"]
            }
            return []
        }
    }

    final class PrimaryCleaningManifestEncounterIDLengthRule: PrimaryCleaningManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCleaningManifest) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCleaningManifestCodePrefixRule: PrimaryCleaningManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryCleaningManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary cleaning manifest.
    final class PrimaryCleaningManifestValidator {
        var rules: [any PrimaryCleaningManifestRule]

        init(rules: [any PrimaryCleaningManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCleaningManifest) -> [String] {
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

        func requireValid(_ item: PrimaryCleaningManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCleaningManifest]) -> [String: [String]] {
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

    static func defaultPrimaryCleaningManifestValidator() -> PrimaryCleaningManifestValidator {
        return PrimaryCleaningManifestValidator(
            rules: [
                PrimaryCleaningManifestTitleLengthRule(maxLength: 86400),
                PrimaryCleaningManifestAllowedCodeRule(allowed: ["legacy"]),
                PrimaryCleaningManifestEncounterIDLengthRule(maxLength: 80),
                PrimaryCleaningManifestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
