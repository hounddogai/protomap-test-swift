import AcmePlatform
import Foundation

extension Labs {
    /// A rule a pending reference range profile must pass. Check returns its problems, or none.
    protocol PendingReferenceRangeProfileRule {
        func check(_ item: PendingReferenceRangeProfile) -> [String]
    }

    final class PendingReferenceRangeProfileRequiredCodeRule: PendingReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeProfileAllowedLabelRule: PendingReferenceRangeProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PendingReferenceRangeProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is blocked"]
            }
            return []
        }
    }

    final class PendingReferenceRangeProfileCreatedAtRangeRule: PendingReferenceRangeProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingReferenceRangeProfile) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingReferenceRangeProfileRequiredLabelRule: PendingReferenceRangeProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingReferenceRangeProfile) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingReferenceRangeProfileVisibleGuardRule: PendingReferenceRangeProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: PendingReferenceRangeProfile) -> [String] {
            if item.visible && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class PendingReferenceRangeProfileCodePrefixRule: PendingReferenceRangeProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PendingReferenceRangeProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending reference range profile.
    final class PendingReferenceRangeProfileValidator {
        var rules: [any PendingReferenceRangeProfileRule]

        init(rules: [any PendingReferenceRangeProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingReferenceRangeProfile) -> [String] {
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

        func requireValid(_ item: PendingReferenceRangeProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingReferenceRangeProfile]) -> [String: [String]] {
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

    static func defaultPendingReferenceRangeProfileValidator() -> PendingReferenceRangeProfileValidator {
        return PendingReferenceRangeProfileValidator(
            rules: [
                PendingReferenceRangeProfileRequiredCodeRule(
                    message: "pending reference range profile needs this field"
                ),
                PendingReferenceRangeProfileAllowedLabelRule(allowed: ["tiered"]),
                PendingReferenceRangeProfileCreatedAtRangeRule(min: 120, max: 3600),
                PendingReferenceRangeProfileRequiredLabelRule(
                    message: "pending reference range profile needs an entry"
                ),
                PendingReferenceRangeProfileVisibleGuardRule(limit: 16),
                PendingReferenceRangeProfileCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
