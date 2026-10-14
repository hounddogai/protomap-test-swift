import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a float pool manifest must pass. Check returns its problems, or none.
    protocol FloatPoolManifestRule {
        func check(_ item: FloatPoolManifest) -> [String]
    }

    final class FloatPoolManifestLabelLengthRule: FloatPoolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolManifestAllowedClinicianIDRule: FloatPoolManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FloatPoolManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is too long"]
            }
            return []
        }
    }

    final class FloatPoolManifestRequiredLabelRule: FloatPoolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FloatPoolManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FloatPoolManifestAllergyLengthRule: FloatPoolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FloatPoolManifest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FloatPoolManifestBudgetRangeRule: FloatPoolManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FloatPoolManifest) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FloatPoolManifestCodePrefixRule: FloatPoolManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FloatPoolManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a float pool manifest.
    final class FloatPoolManifestValidator {
        var rules: [any FloatPoolManifestRule]

        init(rules: [any FloatPoolManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: FloatPoolManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FloatPoolManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FloatPoolManifest]) -> [String: [String]] {
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

    static func defaultFloatPoolManifestValidator() -> FloatPoolManifestValidator {
        return FloatPoolManifestValidator(
            rules: [
                FloatPoolManifestLabelLengthRule(maxLength: 64),
                FloatPoolManifestAllowedClinicianIDRule(allowed: []),
                FloatPoolManifestRequiredLabelRule(message: "float pool manifest needs an entry"),
                FloatPoolManifestAllergyLengthRule(maxLength: 64),
                FloatPoolManifestBudgetRangeRule(min: 7.8, max: 4225.3),
                FloatPoolManifestCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
