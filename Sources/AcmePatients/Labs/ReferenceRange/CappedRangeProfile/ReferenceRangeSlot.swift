import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range slot is in its life cycle.
    enum ReferenceRangeSlotStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One reference range slot, with what the planners need to act on it.
    final class ReferenceRangeSlot {
        var code: String
        var label: String
        var externalRef: String
        var tags: [String]
        var description: String
        var category: String
        var score: Double
        var status: ReferenceRangeSlotStatus

        init(code: String, label: String, externalRef: String, tags: [String], description: String, category: String, score: Double, status: ReferenceRangeSlotStatus) {
            self.code = code
            self.label = label
            self.externalRef = externalRef
            self.tags = tags
            self.description = description
            self.category = category
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeSlotStatus) -> Bool {
            switch status {
            case .draft:
                return next == ReferenceRangeSlotStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == ReferenceRangeSlotStatus.closed
            case .suspended:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
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
            return score
        }

        func copyValue() -> ReferenceRangeSlot {
            return ReferenceRangeSlot(
                code: code,
                label: label,
                externalRef: externalRef,
                tags: tags,
                description: description,
                category: category,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a reference range slot in status draft.
    static func newReferenceRangeSlot(_ code: String, label: String) -> ReferenceRangeSlot {
        return ReferenceRangeSlot(
            code: code,
            label: label,
            externalRef: "",
            tags: [],
            description: "",
            category: "",
            score: 0.0,
            status: ReferenceRangeSlotStatus.draft
        )
    }
}
