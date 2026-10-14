import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board checkpoint must pass. Check returns its problems, or none.
    protocol BedBoardCheckpointRule {
        func check(_ item: BedBoardCheckpoint) -> [String]
    }

    final class BedBoardCheckpointRequiredSpecialtyRule: BedBoardCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardCheckpoint) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardCheckpointPinnedGuardRule: BedBoardCheckpointRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BedBoardCheckpoint) -> [String] {
            if item.pinned && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class BedBoardCheckpointRequiredSegmentRule: BedBoardCheckpointRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardCheckpoint) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardCheckpointAllowedSegmentRule: BedBoardCheckpointRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardCheckpoint) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is duplicated"]
            }
            return []
        }
    }

    final class BedBoardCheckpointTitleLengthRule: BedBoardCheckpointRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardCheckpoint) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardCheckpointCodePrefixRule: BedBoardCheckpointRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardCheckpoint) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a bed board checkpoint.
    final class BedBoardCheckpointValidator {
        var rules: [any BedBoardCheckpointRule]

        init(rules: [any BedBoardCheckpointRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardCheckpoint) -> [String] {
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

        func requireValid(_ item: BedBoardCheckpoint) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardCheckpoint]) -> [String: [String]] {
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

    static func defaultBedBoardCheckpointValidator() -> BedBoardCheckpointValidator {
        return BedBoardCheckpointValidator(
            rules: [
                BedBoardCheckpointRequiredSpecialtyRule(message: "bed board checkpoint needs an entry"),
                BedBoardCheckpointPinnedGuardRule(limit: 16),
                BedBoardCheckpointRequiredSegmentRule(message: "bed board checkpoint needs a value"),
                BedBoardCheckpointAllowedSegmentRule(allowed: ["rolling", "regional"]),
                BedBoardCheckpointTitleLengthRule(maxLength: 1000),
                BedBoardCheckpointCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
