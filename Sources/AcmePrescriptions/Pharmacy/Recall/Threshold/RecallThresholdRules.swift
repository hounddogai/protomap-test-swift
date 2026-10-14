import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall threshold must pass. Check returns its problems, or none.
    protocol RecallThresholdRule {
        func check(_ item: RecallThreshold) -> [String]
    }

    final class RecallThresholdFacilityLengthRule: RecallThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallThreshold) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallThresholdRequiredEncounterIDRule: RecallThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallThreshold) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallThresholdAllowedNameRule: RecallThresholdRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallThreshold) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is expired"]
            }
            return []
        }
    }

    final class RecallThresholdRequiredNameRule: RecallThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallThreshold) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall threshold.
    final class RecallThresholdValidator {
        var rules: [any RecallThresholdRule]

        init(rules: [any RecallThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallThreshold]) -> [String: [String]] {
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

    static func defaultRecallThresholdValidator() -> RecallThresholdValidator {
        return RecallThresholdValidator(
            rules: [
                RecallThresholdFacilityLengthRule(maxLength: 3600),
                RecallThresholdRequiredEncounterIDRule(message: "recall threshold needs this field"),
                RecallThresholdAllowedNameRule(allowed: ["tiered"]),
                RecallThresholdRequiredNameRule(message: "recall threshold needs a value"),
            ]
        )
    }
}
