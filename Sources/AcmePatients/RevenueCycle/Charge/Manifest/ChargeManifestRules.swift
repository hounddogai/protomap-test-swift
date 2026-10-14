import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge manifest must pass. Check returns its problems, or none.
    protocol ChargeManifestRule {
        func check(_ item: ChargeManifest) -> [String]
    }

    final class ChargeManifestAllowedClinicianIDRule: ChargeManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ChargeManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is expired"]
            }
            return []
        }
    }

    final class ChargeManifestRequiredCodeRule: ChargeManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeManifestDiscountRangeRule: ChargeManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeManifest) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeManifestCodeLengthRule: ChargeManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeManifestClinicianIDLengthRule: ChargeManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeManifest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeManifestRequiredClinicianIDRule: ChargeManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeManifest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a charge manifest.
    final class ChargeManifestValidator {
        var rules: [any ChargeManifestRule]

        init(rules: [any ChargeManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeManifest) -> [String] {
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

        func requireValid(_ item: ChargeManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeManifest]) -> [String: [String]] {
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

    static func defaultChargeManifestValidator() -> ChargeManifestValidator {
        return ChargeManifestValidator(
            rules: [
                ChargeManifestAllowedClinicianIDRule(allowed: ["adaptive"]),
                ChargeManifestRequiredCodeRule(message: "charge manifest needs a value"),
                ChargeManifestDiscountRangeRule(min: 3.9, max: 371.5),
                ChargeManifestCodeLengthRule(maxLength: 120),
                ChargeManifestClinicianIDLengthRule(maxLength: 1000),
                ChargeManifestRequiredClinicianIDRule(message: "charge manifest needs this field"),
            ]
        )
    }
}
