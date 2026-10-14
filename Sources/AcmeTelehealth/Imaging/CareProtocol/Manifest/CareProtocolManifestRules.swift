import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol manifest must pass. Check returns its problems, or none.
    protocol CareProtocolManifestRule {
        func check(_ item: CareProtocolManifest) -> [String]
    }

    final class CareProtocolManifestCodeLengthRule: CareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolManifestClinicianIDLengthRule: CareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolManifestAcuityRangeRule: CareProtocolManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolManifestRequiredNameRule: CareProtocolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolManifestRequiredClinicianIDRule: CareProtocolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolManifestCodePrefixRule: CareProtocolManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol manifest.
    final class CareProtocolManifestValidator {
        var rules: [any CareProtocolManifestRule]

        init(rules: [any CareProtocolManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolManifest) -> [String] {
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

        func requireValid(_ item: CareProtocolManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolManifest]) -> [String: [String]] {
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

    static func defaultCareProtocolManifestValidator() -> CareProtocolManifestValidator {
        return CareProtocolManifestValidator(
            rules: [
                CareProtocolManifestCodeLengthRule(maxLength: 16),
                CareProtocolManifestClinicianIDLengthRule(maxLength: 80),
                CareProtocolManifestAcuityRangeRule(min: 16, max: 80),
                CareProtocolManifestRequiredNameRule(message: "care protocol manifest needs this field"),
                CareProtocolManifestRequiredClinicianIDRule(message: "care protocol manifest needs this field"),
                CareProtocolManifestCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
