import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending slot manifest must pass. Check returns its problems, or none.
    protocol PendingSlotManifestRule {
        func check(_ item: PendingSlotManifest) -> [String]
    }

    final class PendingSlotManifestAllowedLabelRule: PendingSlotManifestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingSlotManifest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is out of range"]
            }
            return []
        }
    }

    final class PendingSlotManifestCodePrefixRule: PendingSlotManifestRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingSlotManifest) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PendingSlotManifestRequiredLabelRule: PendingSlotManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSlotManifest) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingSlotManifestScoreRangeRule: PendingSlotManifestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingSlotManifest) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingSlotManifestRequiredCodeRule: PendingSlotManifestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingSlotManifest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a pending slot manifest.
    final class PendingSlotManifestValidator {
        var rules: [any PendingSlotManifestRule]

        init(rules: [any PendingSlotManifestRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingSlotManifest) -> [String] {
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

        func requireValid(_ item: PendingSlotManifest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingSlotManifest]) -> [String: [String]] {
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

    static func defaultPendingSlotManifestValidator() -> PendingSlotManifestValidator {
        return PendingSlotManifestValidator(
            rules: [
                PendingSlotManifestAllowedLabelRule(allowed: ["adaptive", "batched", "capped"]),
                PendingSlotManifestCodePrefixRule(prefix: "X"),
                PendingSlotManifestRequiredLabelRule(message: "pending slot manifest needs a value"),
                PendingSlotManifestScoreRangeRule(min: 8.6, max: 3383.1),
                PendingSlotManifestRequiredCodeRule(message: "pending slot manifest needs this field"),
            ]
        )
    }
}
