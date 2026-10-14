import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol cycle must pass. Check returns its problems, or none.
    protocol CareProtocolCycleRule {
        func check(_ item: CareProtocolCycle) -> [String]
    }

    final class CareProtocolCycleNameLengthRule: CareProtocolCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolCycle) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolCycleAllowedClinicianIDRule: CareProtocolCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CareProtocolCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.clinicianID)) {
                return ["clinician id \(item.clinicianID) is below minimum"]
            }
            return []
        }
    }

    final class CareProtocolCycleRequiredFacilityRule: CareProtocolCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolCycle) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol cycle.
    final class CareProtocolCycleValidator {
        var rules: [any CareProtocolCycleRule]

        init(rules: [any CareProtocolCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolCycle) -> [String] {
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

        func requireValid(_ item: CareProtocolCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolCycle]) -> [String: [String]] {
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

    static func defaultCareProtocolCycleValidator() -> CareProtocolCycleValidator {
        return CareProtocolCycleValidator(
            rules: [
                CareProtocolCycleNameLengthRule(maxLength: 86400),
                CareProtocolCycleAllowedClinicianIDRule(allowed: ["tiered", "primary"]),
                CareProtocolCycleRequiredFacilityRule(message: "care protocol cycle needs a value"),
            ]
        )
    }
}
