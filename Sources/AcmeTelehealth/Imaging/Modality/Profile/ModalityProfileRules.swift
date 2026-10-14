import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality profile must pass. Check returns its problems, or none.
    protocol ModalityProfileRule {
        func check(_ item: ModalityProfile) -> [String]
    }

    final class ModalityProfileRequiredBedRule: ModalityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityProfile) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityProfileCodePrefixRule: ModalityProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ModalityProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ModalityProfileCodeLengthRule: ModalityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ModalityProfileRequiredClinicianIDRule: ModalityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityProfile) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityProfileAllowedContactEmailRule: ModalityProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ModalityProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is unknown"]
            }
            return []
        }
    }

    final class ModalityProfileTitleLengthRule: ModalityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ModalityProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a modality profile.
    final class ModalityProfileValidator {
        var rules: [any ModalityProfileRule]

        init(rules: [any ModalityProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityProfile) -> [String] {
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

        func requireValid(_ item: ModalityProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityProfile]) -> [String: [String]] {
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

    static func defaultModalityProfileValidator() -> ModalityProfileValidator {
        return ModalityProfileValidator(
            rules: [
                ModalityProfileRequiredBedRule(message: "modality profile needs this field"),
                ModalityProfileCodePrefixRule(prefix: "X"),
                ModalityProfileCodeLengthRule(maxLength: 1000),
                ModalityProfileRequiredClinicianIDRule(message: "modality profile needs an entry"),
                ModalityProfileAllowedContactEmailRule(allowed: ["weighted"]),
                ModalityProfileTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
