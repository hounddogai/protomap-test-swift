import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary census checkpoint must pass. Check returns its problems, or none.
    protocol PrimaryCensusCheckpointRule {
        func check(_ item: PrimaryCensusCheckpoint) -> [String]
    }

    final class PrimaryCensusCheckpointAllowedCodeRule: PrimaryCensusCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryCensusCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is unknown"]
            }
            return []
        }
    }

    final class PrimaryCensusCheckpointCopayRangeRule: PrimaryCensusCheckpointRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryCensusCheckpoint) -> [String] {
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

    final class PrimaryCensusCheckpointCodeLengthRule: PrimaryCensusCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryCensusCheckpoint) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryCensusCheckpointRequiredSegmentRule: PrimaryCensusCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryCensusCheckpoint) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary census checkpoint.
    final class PrimaryCensusCheckpointValidator {
        var rules: [any PrimaryCensusCheckpointRule]

        init(rules: [any PrimaryCensusCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryCensusCheckpoint) -> [String] {
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

        func requireValid(_ item: PrimaryCensusCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryCensusCheckpoint]) -> [String: [String]] {
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

    static func defaultPrimaryCensusCheckpointValidator() -> PrimaryCensusCheckpointValidator {
        return PrimaryCensusCheckpointValidator(
            rules: [
                PrimaryCensusCheckpointAllowedCodeRule(allowed: []),
                PrimaryCensusCheckpointCopayRangeRule(min: 5.7, max: 3401.7),
                PrimaryCensusCheckpointCodeLengthRule(maxLength: 86400),
                PrimaryCensusCheckpointRequiredSegmentRule(message: "primary census checkpoint needs a value"),
            ]
        )
    }
}
