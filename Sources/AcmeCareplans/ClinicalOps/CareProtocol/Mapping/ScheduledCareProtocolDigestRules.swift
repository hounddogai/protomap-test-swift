import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a scheduled care protocol digest must pass. Check returns its problems, or none.
    protocol ScheduledCareProtocolDigestRule {
        func check(_ item: ScheduledCareProtocolDigest) -> [String]
    }

    final class ScheduledCareProtocolDigestCodeLengthRule: ScheduledCareProtocolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolDigestRequiredEncounterIDRule: ScheduledCareProtocolDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCareProtocolDigest) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCareProtocolDigestNameLengthRule: ScheduledCareProtocolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolDigest) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolDigestCopayRangeRule: ScheduledCareProtocolDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCareProtocolDigest) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledCareProtocolDigestEncounterIDLengthRule: ScheduledCareProtocolDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCareProtocolDigest) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCareProtocolDigestAllowedLabelRule: ScheduledCareProtocolDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledCareProtocolDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled care protocol digest.
    final class ScheduledCareProtocolDigestValidator {
        var rules: [any ScheduledCareProtocolDigestRule]

        init(rules: [any ScheduledCareProtocolDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCareProtocolDigest) -> [String] {
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

        func requireValid(_ item: ScheduledCareProtocolDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCareProtocolDigest]) -> [String: [String]] {
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

    static func defaultScheduledCareProtocolDigestValidator() -> ScheduledCareProtocolDigestValidator {
        return ScheduledCareProtocolDigestValidator(
            rules: [
                ScheduledCareProtocolDigestCodeLengthRule(maxLength: 32),
                ScheduledCareProtocolDigestRequiredEncounterIDRule(
                    message: "scheduled care protocol digest needs this field"
                ),
                ScheduledCareProtocolDigestNameLengthRule(maxLength: 120),
                ScheduledCareProtocolDigestCopayRangeRule(min: 8.3, max: 694.3),
                ScheduledCareProtocolDigestEncounterIDLengthRule(maxLength: 3600),
                ScheduledCareProtocolDigestAllowedLabelRule(allowed: ["legacy"]),
            ]
        )
    }
}
