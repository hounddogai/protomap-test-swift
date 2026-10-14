import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted modality profile must pass. Check returns its problems, or none.
    protocol WeightedModalityProfileRule {
        func check(_ item: WeightedModalityProfile) -> [String]
    }

    final class WeightedModalityProfileCodeLengthRule: WeightedModalityProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedModalityProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedModalityProfileAllowedNameRule: WeightedModalityProfileRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedModalityProfile) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is below minimum"]
            }
            return []
        }
    }

    final class WeightedModalityProfileRequiredCodeRule: WeightedModalityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedModalityProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedModalityProfileRequiredAllergyRule: WeightedModalityProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedModalityProfile) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedModalityProfilePinnedGuardRule: WeightedModalityProfileRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: WeightedModalityProfile) -> [String] {
            if item.pinned && (item.limit > limit) {
                return ["limit \(item.limit) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted modality profile.
    final class WeightedModalityProfileValidator {
        var rules: [any WeightedModalityProfileRule]

        init(rules: [any WeightedModalityProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedModalityProfile) -> [String] {
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

        func requireValid(_ item: WeightedModalityProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedModalityProfile]) -> [String: [String]] {
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

    static func defaultWeightedModalityProfileValidator() -> WeightedModalityProfileValidator {
        return WeightedModalityProfileValidator(
            rules: [
                WeightedModalityProfileCodeLengthRule(maxLength: 1000),
                WeightedModalityProfileAllowedNameRule(allowed: []),
                WeightedModalityProfileRequiredCodeRule(message: "weighted modality profile needs a value"),
                WeightedModalityProfileRequiredAllergyRule(message: "weighted modality profile needs a value"),
                WeightedModalityProfilePinnedGuardRule(limit: 16),
            ]
        )
    }
}
