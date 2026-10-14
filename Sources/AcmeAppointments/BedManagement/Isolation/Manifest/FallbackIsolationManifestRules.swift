import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a fallback isolation manifest must pass. Check returns its problems, or none.
    protocol FallbackIsolationManifestRule {
        func check(_ item: FallbackIsolationManifest) -> [String]
    }

    final class FallbackIsolationManifestRequiredNameRule: FallbackIsolationManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackIsolationManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackIsolationManifestUpdatedAtRangeRule: FallbackIsolationManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackIsolationManifest) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackIsolationManifestCodeLengthRule: FallbackIsolationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackIsolationManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackIsolationManifestAllowedCodeRule: FallbackIsolationManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackIsolationManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class FallbackIsolationManifestNameLengthRule: FallbackIsolationManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackIsolationManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback isolation manifest.
    final class FallbackIsolationManifestValidator {
        var rules: [any FallbackIsolationManifestRule]

        init(rules: [any FallbackIsolationManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackIsolationManifest) -> [String] {
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

        func requireValid(_ item: FallbackIsolationManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackIsolationManifest]) -> [String: [String]] {
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

    static func defaultFallbackIsolationManifestValidator() -> FallbackIsolationManifestValidator {
        return FallbackIsolationManifestValidator(
            rules: [
                FallbackIsolationManifestRequiredNameRule(message: "fallback isolation manifest needs an entry"),
                FallbackIsolationManifestUpdatedAtRangeRule(min: 3600, max: 86400),
                FallbackIsolationManifestCodeLengthRule(maxLength: 80),
                FallbackIsolationManifestAllowedCodeRule(allowed: ["seasonal", "default", "legacy"]),
                FallbackIsolationManifestNameLengthRule(maxLength: 255),
            ]
        )
    }
}
