import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a global denial manifest must pass. Check returns its problems, or none.
    protocol GlobalDenialManifestRule {
        func check(_ item: GlobalDenialManifest) -> [String]
    }

    final class GlobalDenialManifestDescriptionLengthRule: GlobalDenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDenialManifest) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDenialManifestDosageMgRangeRule: GlobalDenialManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDenialManifest) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalDenialManifestRequiredPhoneRule: GlobalDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDenialManifest) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDenialManifestCodeLengthRule: GlobalDenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDenialManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalDenialManifestRequiredDescriptionRule: GlobalDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDenialManifest) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDenialManifestWeightRangeRule: GlobalDenialManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDenialManifest) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global denial manifest.
    final class GlobalDenialManifestValidator {
        var rules: [any GlobalDenialManifestRule]

        init(rules: [any GlobalDenialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDenialManifest) -> [String] {
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

        func requireValid(_ item: GlobalDenialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDenialManifest]) -> [String: [String]] {
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

    static func defaultGlobalDenialManifestValidator() -> GlobalDenialManifestValidator {
        return GlobalDenialManifestValidator(
            rules: [
                GlobalDenialManifestDescriptionLengthRule(maxLength: 86400),
                GlobalDenialManifestDosageMgRangeRule(min: 1.0, max: 4089.0),
                GlobalDenialManifestRequiredPhoneRule(message: "global denial manifest needs this field"),
                GlobalDenialManifestCodeLengthRule(maxLength: 86400),
                GlobalDenialManifestRequiredDescriptionRule(message: "global denial manifest needs an entry"),
                GlobalDenialManifestWeightRangeRule(min: 8.2, max: 482.9),
            ]
        )
    }
}
