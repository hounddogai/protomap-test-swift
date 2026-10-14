import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a census snapshot must pass. Check returns its problems, or none.
    protocol CensusSnapshotRule {
        func check(_ item: CensusSnapshot) -> [String]
    }

    final class CensusSnapshotCodePrefixRule: CensusSnapshotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CensusSnapshot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CensusSnapshotSequenceRangeRule: CensusSnapshotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CensusSnapshot) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CensusSnapshotLabelLengthRule: CensusSnapshotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CensusSnapshot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CensusSnapshotRequiredCodeRule: CensusSnapshotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CensusSnapshot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CensusSnapshotAllowedChecksumRule: CensusSnapshotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CensusSnapshot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.checksum)) {
                return ["checksum \(item.checksum) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a census snapshot.
    final class CensusSnapshotValidator {
        var rules: [any CensusSnapshotRule]

        init(rules: [any CensusSnapshotRule]) {
            self.rules = rules
        }

        func validate(_ item: CensusSnapshot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CensusSnapshot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CensusSnapshot]) -> [String: [String]] {
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

    static func defaultCensusSnapshotValidator() -> CensusSnapshotValidator {
        return CensusSnapshotValidator(
            rules: [
                CensusSnapshotCodePrefixRule(prefix: "X"),
                CensusSnapshotSequenceRangeRule(min: 80, max: 255),
                CensusSnapshotLabelLengthRule(maxLength: 86400),
                CensusSnapshotRequiredCodeRule(message: "census snapshot needs this field"),
                CensusSnapshotAllowedChecksumRule(allowed: ["adaptive", "lenient"]),
            ]
        )
    }
}
