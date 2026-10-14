import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled witness manifest must pass. Check returns its problems, or none.
    protocol ScheduledWitnessManifestRule {
        func check(_ item: ScheduledWitnessManifest) -> [String]
    }

    final class ScheduledWitnessManifestSourceLengthRule: ScheduledWitnessManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledWitnessManifest) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledWitnessManifestCodePrefixRule: ScheduledWitnessManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledWitnessManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledWitnessManifestVisitMinutesRangeRule: ScheduledWitnessManifestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledWitnessManifest) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledWitnessManifestRequiredNameRule: ScheduledWitnessManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWitnessManifest) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledWitnessManifestArchivedGuardRule: ScheduledWitnessManifestRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledWitnessManifest) -> [String] {
            if item.archived && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ScheduledWitnessManifestCodeLengthRule: ScheduledWitnessManifestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledWitnessManifest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled witness manifest.
    final class ScheduledWitnessManifestValidator {
        var rules: [any ScheduledWitnessManifestRule]

        init(rules: [any ScheduledWitnessManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledWitnessManifest) -> [String] {
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

        func requireValid(_ item: ScheduledWitnessManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledWitnessManifest]) -> [String: [String]] {
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

    static func defaultScheduledWitnessManifestValidator() -> ScheduledWitnessManifestValidator {
        return ScheduledWitnessManifestValidator(
            rules: [
                ScheduledWitnessManifestSourceLengthRule(maxLength: 86400),
                ScheduledWitnessManifestCodePrefixRule(prefix: "Q"),
                ScheduledWitnessManifestVisitMinutesRangeRule(min: 32, max: 64),
                ScheduledWitnessManifestRequiredNameRule(message: "scheduled witness manifest needs this field"),
                ScheduledWitnessManifestArchivedGuardRule(limit: 255),
                ScheduledWitnessManifestCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
