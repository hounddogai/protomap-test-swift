import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient care protocol manifest must pass. Check returns its problems, or none.
    protocol LenientCareProtocolManifestRule {
        func check(_ item: LenientCareProtocolManifest) -> [String]
    }

    final class LenientCareProtocolManifestAllowedChannelRule: LenientCareProtocolManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientCareProtocolManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.channel)) {
                return ["channel \(item.channel) is stale"]
            }
            return []
        }
    }

    final class LenientCareProtocolManifestChannelLengthRule: LenientCareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolManifest) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareProtocolManifestClinicianIDLengthRule: LenientCareProtocolManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientCareProtocolManifest) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientCareProtocolManifestRequiredClinicianIDRule: LenientCareProtocolManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientCareProtocolManifest) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient care protocol manifest.
    final class LenientCareProtocolManifestValidator {
        var rules: [any LenientCareProtocolManifestRule]

        init(rules: [any LenientCareProtocolManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientCareProtocolManifest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientCareProtocolManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientCareProtocolManifest]) -> [String: [String]] {
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

    static func defaultLenientCareProtocolManifestValidator() -> LenientCareProtocolManifestValidator {
        return LenientCareProtocolManifestValidator(
            rules: [
                LenientCareProtocolManifestAllowedChannelRule(allowed: ["strict", "capped", "seasonal"]),
                LenientCareProtocolManifestChannelLengthRule(maxLength: 3600),
                LenientCareProtocolManifestClinicianIDLengthRule(maxLength: 120),
                LenientCareProtocolManifestRequiredClinicianIDRule(
                    message: "lenient care protocol manifest needs this field"
                ),
            ]
        )
    }
}
