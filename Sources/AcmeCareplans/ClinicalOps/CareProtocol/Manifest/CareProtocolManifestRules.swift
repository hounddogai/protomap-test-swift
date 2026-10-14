import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol manifest must pass. Check returns its problems, or none.
    protocol CareProtocolManifestRule {
        func check(_ item: CareProtocolManifest) -> [String]
    }

    final class CareProtocolManifestRequiredNameRule: CareProtocolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolManifestMaximumRangeRule: CareProtocolManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolManifest) -> [String] {
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

    final class CareProtocolManifestRegionLengthRule: CareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolManifestCodeLengthRule: CareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolManifestAllowedCodeRule: CareProtocolManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    final class CareProtocolManifestRequiredRegionRule: CareProtocolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol manifest.
    final class CareProtocolManifestValidator {
        var rules: [any CareProtocolManifestRule]

        init(rules: [any CareProtocolManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolManifest]) -> [String: [String]] {
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

    static func defaultCareProtocolManifestValidator() -> CareProtocolManifestValidator {
        return CareProtocolManifestValidator(
            rules: [
                CareProtocolManifestRequiredNameRule(message: "care protocol manifest needs a value"),
                CareProtocolManifestMaximumRangeRule(min: 4.6, max: 1553.6),
                CareProtocolManifestRegionLengthRule(maxLength: 80),
                CareProtocolManifestCodeLengthRule(maxLength: 120),
                CareProtocolManifestAllowedCodeRule(allowed: []),
                CareProtocolManifestRequiredRegionRule(message: "care protocol manifest needs a value"),
            ]
        )
    }
}
