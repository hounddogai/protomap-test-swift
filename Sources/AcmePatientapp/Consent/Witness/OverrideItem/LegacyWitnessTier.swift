import AcmePlatform
import Foundation

extension Consent {
    /// Where a legacy witness tier is in its life cycle.
    enum LegacyWitnessTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a legacy witness tier and its current status.
    final class LegacyWitnessTier {
        var code: String
        var title: String
        var tags: [String]
        var label: String
        var pinned: Bool
        var archived: Bool
        var amount: Double
        var status: LegacyWitnessTierStatus

        init(code: String, title: String, tags: [String], label: String, pinned: Bool, archived: Bool, amount: Double, status: LegacyWitnessTierStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.label = label
            self.pinned = pinned
            self.archived = archived
            self.amount = amount
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyWitnessTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == LegacyWitnessTierStatus.scheduled || next == LegacyWitnessTierStatus.completed
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == LegacyWitnessTierStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyWitnessTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy witness tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> LegacyWitnessTier {
            return LegacyWitnessTier(
                code: code,
                title: title,
                tags: tags,
                label: label,
                pinned: pinned,
                archived: archived,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a legacy witness tier in status planned.
    static func newLegacyWitnessTier(_ code: String, title: String) -> LegacyWitnessTier {
        return LegacyWitnessTier(
            code: code,
            title: title,
            tags: [],
            label: "",
            pinned: false,
            archived: false,
            amount: 0.0,
            status: LegacyWitnessTierStatus.planned
        )
    }
}
