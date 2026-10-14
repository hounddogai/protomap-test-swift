import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness snapshot must pass. Check returns its problems, or none.
    protocol WitnessSnapshotRule {
        func check(_ item: WitnessSnapshot) -> [String]
    }

    final class WitnessSnapshotFacilityLengthRule: WitnessSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessSnapshot) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessSnapshotCodePrefixRule: WitnessSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessSnapshotRequiredTitleRule: WitnessSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessSnapshot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessSnapshotRequiredFacilityRule: WitnessSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessSnapshot) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessSnapshotCodeLengthRule: WitnessSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessSnapshot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a witness snapshot.
    final class WitnessSnapshotValidator {
        var rules: [any WitnessSnapshotRule]

        init(rules: [any WitnessSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessSnapshot) -> [String] {
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

        func requireValid(_ item: WitnessSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessSnapshot]) -> [String: [String]] {
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

    static func defaultWitnessSnapshotValidator() -> WitnessSnapshotValidator {
        return WitnessSnapshotValidator(
            rules: [
                WitnessSnapshotFacilityLengthRule(maxLength: 120),
                WitnessSnapshotCodePrefixRule(prefix: "ACM"),
                WitnessSnapshotRequiredTitleRule(message: "witness snapshot needs this field"),
                WitnessSnapshotRequiredFacilityRule(message: "witness snapshot needs an entry"),
                WitnessSnapshotCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
