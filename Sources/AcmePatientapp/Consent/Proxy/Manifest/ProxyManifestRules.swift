import AcmePlatform
import Foundation

extension Consent {
    /// A rule a proxy manifest must pass. Check returns its problems, or none.
    protocol ProxyManifestRule {
        func check(_ item: ProxyManifest) -> [String]
    }

    final class ProxyManifestNameLengthRule: ProxyManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProxyManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProxyManifestRequiredNameRule: ProxyManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProxyManifestScoreRangeRule: ProxyManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProxyManifest) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ProxyManifestRequiredCodeRule: ProxyManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProxyManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a proxy manifest.
    final class ProxyManifestValidator {
        var rules: [any ProxyManifestRule]

        init(rules: [any ProxyManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ProxyManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProxyManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProxyManifest]) -> [String: [String]] {
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

    static func defaultProxyManifestValidator() -> ProxyManifestValidator {
        return ProxyManifestValidator(
            rules: [
                ProxyManifestNameLengthRule(maxLength: 3600),
                ProxyManifestRequiredNameRule(message: "proxy manifest needs a value"),
                ProxyManifestScoreRangeRule(min: 5.9, max: 252.4),
                ProxyManifestRequiredCodeRule(message: "proxy manifest needs this field"),
            ]
        )
    }
}
