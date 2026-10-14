import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy accession threshold must pass. Check returns its problems, or none.
    protocol LegacyAccessionThresholdRule {
        func check(_ item: LegacyAccessionThreshold) -> [String]
    }

    final class LegacyAccessionThresholdRequiredCodeRule: LegacyAccessionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAccessionThreshold) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAccessionThresholdRequiredLabelRule: LegacyAccessionThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyAccessionThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyAccessionThresholdPinnedGuardRule: LegacyAccessionThresholdRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: LegacyAccessionThreshold) -> [String] {
            if item.pinned && (item.createdAt > limit) {
                return ["created at \(item.createdAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class LegacyAccessionThresholdAllowedExternalRefRule: LegacyAccessionThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LegacyAccessionThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.externalRef)) {
                return ["external ref \(item.externalRef) is too long"]
            }
            return []
        }
    }

    final class LegacyAccessionThresholdLabelLengthRule: LegacyAccessionThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyAccessionThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy accession threshold.
    final class LegacyAccessionThresholdValidator {
        var rules: [any LegacyAccessionThresholdRule]

        init(rules: [any LegacyAccessionThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyAccessionThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyAccessionThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyAccessionThreshold]) -> [String: [String]] {
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

    static func defaultLegacyAccessionThresholdValidator() -> LegacyAccessionThresholdValidator {
        return LegacyAccessionThresholdValidator(
            rules: [
                LegacyAccessionThresholdRequiredCodeRule(message: "legacy accession threshold needs a value"),
                LegacyAccessionThresholdRequiredLabelRule(message: "legacy accession threshold needs this field"),
                LegacyAccessionThresholdPinnedGuardRule(limit: 86400),
                LegacyAccessionThresholdAllowedExternalRefRule(allowed: ["tiered", "strict"]),
                LegacyAccessionThresholdLabelLengthRule(maxLength: 1000),
            ]
        )
    }
}
