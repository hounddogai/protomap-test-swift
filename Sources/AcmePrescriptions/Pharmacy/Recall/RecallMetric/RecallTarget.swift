import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall target is in its life cycle.
    enum RecallTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A recall target as the recall team keeps it.
    final class RecallTarget {
        var code: String
        var name: String
        var startsAt: Int
        var pinned: Bool
        var version: Int
        var minimum: Double
        var label: String
        var createdAt: Int
        var checksum: String
        var attributes: [String: String]
        var status: RecallTargetStatus

        init(code: String, name: String, startsAt: Int, pinned: Bool, version: Int, minimum: Double, label: String, createdAt: Int, checksum: String, attributes: [String: String], status: RecallTargetStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.pinned = pinned
            self.version = version
            self.minimum = minimum
            self.label = label
            self.createdAt = createdAt
            self.checksum = checksum
            self.attributes = attributes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RecallTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RecallTargetStatus.inReview || next == RecallTargetStatus.archived
            case .inReview:
                return next == RecallTargetStatus.resolved || next == RecallTargetStatus.archived
            case .resolved:
                return next == RecallTargetStatus.archived
            case .reopened:
                return next == RecallTargetStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RecallTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("recall target") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func netTotal() -> Double {
            return ((Double(startsAt) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> RecallTarget {
            return RecallTarget(
                code: code,
                name: name,
                startsAt: startsAt,
                pinned: pinned,
                version: version,
                minimum: minimum,
                label: label,
                createdAt: createdAt,
                checksum: checksum,
                attributes: attributes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a recall target in status open.
    static func newRecallTarget(_ code: String, name: String) -> RecallTarget {
        return RecallTarget(
            code: code,
            name: name,
            startsAt: 0,
            pinned: false,
            version: 0,
            minimum: 0.0,
            label: "",
            createdAt: 0,
            checksum: "",
            attributes: [:],
            status: RecallTargetStatus.`open`
        )
    }
}
