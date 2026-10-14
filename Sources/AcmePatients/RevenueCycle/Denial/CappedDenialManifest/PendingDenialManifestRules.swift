import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending denial manifest must pass. Check returns its problems, or none.
    protocol PendingDenialManifestRule {
        func check(_ item: PendingDenialManifest) -> [String]
    }

    final class PendingDenialManifestRequiredContactEmailRule: PendingDenialManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingDenialManifest) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingDenialManifestTitleLengthRule: PendingDenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDenialManifest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDenialManifestContactEmailLengthRule: PendingDenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDenialManifest) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingDenialManifestCodePrefixRule: PendingDenialManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingDenialManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingDenialManifestApprovedGuardRule: PendingDenialManifestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingDenialManifest) -> [String] {
            if item.approved && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class PendingDenialManifestNameLengthRule: PendingDenialManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingDenialManifest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending denial manifest.
    final class PendingDenialManifestValidator {
        var rules: [any PendingDenialManifestRule]

        init(rules: [any PendingDenialManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingDenialManifest) -> [String] {
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

        func requireValid(_ item: PendingDenialManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingDenialManifest]) -> [String: [String]] {
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

    static func defaultPendingDenialManifestValidator() -> PendingDenialManifestValidator {
        return PendingDenialManifestValidator(
            rules: [
                PendingDenialManifestRequiredContactEmailRule(message: "pending denial manifest needs this field"),
                PendingDenialManifestTitleLengthRule(maxLength: 120),
                PendingDenialManifestContactEmailLengthRule(maxLength: 120),
                PendingDenialManifestCodePrefixRule(prefix: "Q"),
                PendingDenialManifestApprovedGuardRule(limit: 1000),
                PendingDenialManifestNameLengthRule(maxLength: 32),
            ]
        )
    }
}
