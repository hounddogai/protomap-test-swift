import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert manifest must pass. Check returns its problems, or none.
    protocol AlertManifestRule {
        func check(_ item: AlertManifest) -> [String]
    }

    final class AlertManifestCodeLengthRule: AlertManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertManifestAllowedNameRule: AlertManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AlertManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class AlertManifestNameLengthRule: AlertManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertManifestRequiredNameRule: AlertManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertManifestAcuityRangeRule: AlertManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertManifest) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a alert manifest.
    final class AlertManifestValidator {
        var rules: [any AlertManifestRule]

        init(rules: [any AlertManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertManifest]) -> [String: [String]] {
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

    static func defaultAlertManifestValidator() -> AlertManifestValidator {
        return AlertManifestValidator(
            rules: [
                AlertManifestCodeLengthRule(maxLength: 64),
                AlertManifestAllowedNameRule(allowed: []),
                AlertManifestNameLengthRule(maxLength: 16),
                AlertManifestRequiredNameRule(message: "alert manifest needs a value"),
                AlertManifestAcuityRangeRule(min: 80, max: 255),
            ]
        )
    }
}
