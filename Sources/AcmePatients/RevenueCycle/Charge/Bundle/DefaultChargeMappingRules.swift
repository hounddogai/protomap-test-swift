import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default charge mapping must pass. Check returns its problems, or none.
    protocol DefaultChargeMappingRule {
        func check(_ item: DefaultChargeMapping) -> [String]
    }

    final class DefaultChargeMappingOwnerIDLengthRule: DefaultChargeMappingRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultChargeMapping) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultChargeMappingAllowedClinicianIDRule: DefaultChargeMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DefaultChargeMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is above maximum"]
            }
            return []
        }
    }

    final class DefaultChargeMappingVersionRangeRule: DefaultChargeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultChargeMapping) -> [String] {
            let value = item.version
            if value < min || value > max {
                return ["version \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultChargeMappingAcuityRangeRule: DefaultChargeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultChargeMapping) -> [String] {
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

    final class DefaultChargeMappingMaximumRangeRule: DefaultChargeMappingRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultChargeMapping) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultChargeMappingRequiredClinicianIDRule: DefaultChargeMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultChargeMapping) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default charge mapping.
    final class DefaultChargeMappingValidator {
        var rules: [any DefaultChargeMappingRule]

        init(rules: [any DefaultChargeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultChargeMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultChargeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultChargeMapping]) -> [String: [String]] {
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

    static func defaultDefaultChargeMappingValidator() -> DefaultChargeMappingValidator {
        return DefaultChargeMappingValidator(
            rules: [
                DefaultChargeMappingOwnerIDLengthRule(maxLength: 3600),
                DefaultChargeMappingAllowedClinicianIDRule(allowed: []),
                DefaultChargeMappingVersionRangeRule(min: 16, max: 86400),
                DefaultChargeMappingAcuityRangeRule(min: 80, max: 255),
                DefaultChargeMappingMaximumRangeRule(min: 4.0, max: 1068.2),
                DefaultChargeMappingRequiredClinicianIDRule(message: "default charge mapping needs this field"),
            ]
        )
    }
}
