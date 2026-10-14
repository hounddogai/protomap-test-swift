import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a fallback closure manifest must pass. Check returns its problems, or none.
    protocol FallbackClosureManifestRule {
        func check(_ item: FallbackClosureManifest) -> [String]
    }

    final class FallbackClosureManifestRequiredCodeRule: FallbackClosureManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackClosureManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackClosureManifestCodeLengthRule: FallbackClosureManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackClosureManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackClosureManifestRegionLengthRule: FallbackClosureManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackClosureManifest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback closure manifest.
    final class FallbackClosureManifestValidator {
        var rules: [any FallbackClosureManifestRule]

        init(rules: [any FallbackClosureManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackClosureManifest) -> [String] {
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

        func requireValid(_ item: FallbackClosureManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackClosureManifest]) -> [String: [String]] {
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

    static func defaultFallbackClosureManifestValidator() -> FallbackClosureManifestValidator {
        return FallbackClosureManifestValidator(
            rules: [
                FallbackClosureManifestRequiredCodeRule(message: "fallback closure manifest needs this field"),
                FallbackClosureManifestCodeLengthRule(maxLength: 80),
                FallbackClosureManifestRegionLengthRule(maxLength: 16),
            ]
        )
    }
}
