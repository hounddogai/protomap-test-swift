import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a strict interaction manifest must pass. Check returns its problems, or none.
    protocol StrictInteractionManifestRule {
        func check(_ item: StrictInteractionManifest) -> [String]
    }

    final class StrictInteractionManifestAllowedLabelRule: StrictInteractionManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StrictInteractionManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is inconsistent"]
            }
            return []
        }
    }

    final class StrictInteractionManifestRequiredCodeRule: StrictInteractionManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictInteractionManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictInteractionManifestActiveGuardRule: StrictInteractionManifestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictInteractionManifest) -> [String] {
            if item.active && (item.acuity > limit) {
                return ["acuity \(item.acuity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    final class StrictInteractionManifestCodeLengthRule: StrictInteractionManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictInteractionManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictInteractionManifestAmountRangeRule: StrictInteractionManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictInteractionManifest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictInteractionManifestCodePrefixRule: StrictInteractionManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictInteractionManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict interaction manifest.
    final class StrictInteractionManifestValidator {
        var rules: [any StrictInteractionManifestRule]

        init(rules: [any StrictInteractionManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictInteractionManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictInteractionManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictInteractionManifest]) -> [String: [String]] {
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

    static func defaultStrictInteractionManifestValidator() -> StrictInteractionManifestValidator {
        return StrictInteractionManifestValidator(
            rules: [
                StrictInteractionManifestAllowedLabelRule(allowed: ["scheduled"]),
                StrictInteractionManifestRequiredCodeRule(message: "strict interaction manifest needs an entry"),
                StrictInteractionManifestActiveGuardRule(limit: 3600),
                StrictInteractionManifestCodeLengthRule(maxLength: 120),
                StrictInteractionManifestAmountRangeRule(min: 5.4, max: 779.9),
                StrictInteractionManifestCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
