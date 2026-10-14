import AcmePlatform
import Foundation

extension Labs {
    /// A rule a specimen checkpoint must pass. Check returns its problems, or none.
    protocol SpecimenCheckpointRule {
        func check(_ item: SpecimenCheckpoint) -> [String]
    }

    final class SpecimenCheckpointVisibleGuardRule: SpecimenCheckpointRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: SpecimenCheckpoint) -> [String] {
            if item.visible && (item.priority > limit) {
                return ["priority \(item.priority) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class SpecimenCheckpointCodeLengthRule: SpecimenCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SpecimenCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SpecimenCheckpointRequiredFacilityRule: SpecimenCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenCheckpoint) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenCheckpointAllowedLabelRule: SpecimenCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SpecimenCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class SpecimenCheckpointRequiredLabelRule: SpecimenCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenCheckpoint) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SpecimenCheckpointRequiredExternalRefRule: SpecimenCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SpecimenCheckpoint) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a specimen checkpoint.
    final class SpecimenCheckpointValidator {
        var rules: [any SpecimenCheckpointRule]

        init(rules: [any SpecimenCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: SpecimenCheckpoint) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SpecimenCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SpecimenCheckpoint]) -> [String: [String]] {
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

    static func defaultSpecimenCheckpointValidator() -> SpecimenCheckpointValidator {
        return SpecimenCheckpointValidator(
            rules: [
                SpecimenCheckpointVisibleGuardRule(limit: 255),
                SpecimenCheckpointCodeLengthRule(maxLength: 120),
                SpecimenCheckpointRequiredFacilityRule(message: "specimen checkpoint needs an entry"),
                SpecimenCheckpointAllowedLabelRule(allowed: []),
                SpecimenCheckpointRequiredLabelRule(message: "specimen checkpoint needs an entry"),
                SpecimenCheckpointRequiredExternalRefRule(message: "specimen checkpoint needs an entry"),
            ]
        )
    }
}
