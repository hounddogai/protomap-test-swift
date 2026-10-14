import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional care protocol manifest must pass. Check returns its problems, or none.
    protocol RegionalCareProtocolManifestRule {
        func check(_ item: RegionalCareProtocolManifest) -> [String]
    }

    final class RegionalCareProtocolManifestLabelLengthRule: RegionalCareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolManifest) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolManifestRequiredClinicianIDRule: RegionalCareProtocolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolManifest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareProtocolManifestCodeLengthRule: RegionalCareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolManifestApprovedGuardRule: RegionalCareProtocolManifestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalCareProtocolManifest) -> [String] {
            if item.approved && (item.retries > limit) {
                return ["retries \(item.retries) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RegionalCareProtocolManifestAllergyLengthRule: RegionalCareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareProtocolManifest) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareProtocolManifestRequiredAllergyRule: RegionalCareProtocolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareProtocolManifest) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a regional care protocol manifest.
    final class RegionalCareProtocolManifestValidator {
        var rules: [any RegionalCareProtocolManifestRule]

        init(rules: [any RegionalCareProtocolManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareProtocolManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalCareProtocolManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareProtocolManifest]) -> [String: [String]] {
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

    static func defaultRegionalCareProtocolManifestValidator() -> RegionalCareProtocolManifestValidator {
        return RegionalCareProtocolManifestValidator(
            rules: [
                RegionalCareProtocolManifestLabelLengthRule(maxLength: 64),
                RegionalCareProtocolManifestRequiredClinicianIDRule(
                    message: "regional care protocol manifest needs an entry"
                ),
                RegionalCareProtocolManifestCodeLengthRule(maxLength: 32),
                RegionalCareProtocolManifestApprovedGuardRule(limit: 120),
                RegionalCareProtocolManifestAllergyLengthRule(maxLength: 80),
                RegionalCareProtocolManifestRequiredAllergyRule(
                    message: "regional care protocol manifest needs an entry"
                ),
            ]
        )
    }
}
