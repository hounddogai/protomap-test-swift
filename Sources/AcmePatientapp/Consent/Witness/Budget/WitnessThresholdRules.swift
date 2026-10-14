import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness threshold must pass. Check returns its problems, or none.
    protocol WitnessThresholdRule {
        func check(_ item: WitnessThreshold) -> [String]
    }

    final class WitnessThresholdRequiredClinicianIDRule: WitnessThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessThreshold) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessThresholdOwnerIDLengthRule: WitnessThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessThreshold) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessThresholdTitleLengthRule: WitnessThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness threshold.
    final class WitnessThresholdValidator {
        var rules: [any WitnessThresholdRule]

        init(rules: [any WitnessThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessThreshold) -> [String] {
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

        func requireValid(_ item: WitnessThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessThreshold]) -> [String: [String]] {
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

    static func defaultWitnessThresholdValidator() -> WitnessThresholdValidator {
        return WitnessThresholdValidator(
            rules: [
                WitnessThresholdRequiredClinicianIDRule(message: "witness threshold needs an entry"),
                WitnessThresholdOwnerIDLengthRule(maxLength: 255),
                WitnessThresholdTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
