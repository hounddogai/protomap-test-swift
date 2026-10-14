import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a lenient denial manifest must pass. Check returns its problems, or none.
    protocol LenientDenialManifestRule {
        func check(_ item: LenientDenialManifest) -> [String]
    }

    final class LenientDenialManifestRequiredLabelRule: LenientDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDenialManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDenialManifestLimitRangeRule: LenientDenialManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDenialManifest) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientDenialManifestLabelLengthRule: LenientDenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientDenialManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientDenialManifestRequiredPayerRule: LenientDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDenialManifest) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient denial manifest.
    final class LenientDenialManifestValidator {
        var rules: [any LenientDenialManifestRule]

        init(rules: [any LenientDenialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDenialManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientDenialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDenialManifest]) -> [String: [String]] {
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

    static func defaultLenientDenialManifestValidator() -> LenientDenialManifestValidator {
        return LenientDenialManifestValidator(
            rules: [
                LenientDenialManifestRequiredLabelRule(message: "lenient denial manifest needs a value"),
                LenientDenialManifestLimitRangeRule(min: 255, max: 255),
                LenientDenialManifestLabelLengthRule(maxLength: 1000),
                LenientDenialManifestRequiredPayerRule(message: "lenient denial manifest needs an entry"),
            ]
        )
    }
}
