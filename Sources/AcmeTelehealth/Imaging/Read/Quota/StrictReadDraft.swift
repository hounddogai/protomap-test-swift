import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict read draft is in its life cycle.
    enum StrictReadDraftStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One strict read draft, with what the planners need to act on it.
    final class StrictReadDraft {
        var code: String
        var title: String
        var label: String
        var startsAt: Int
        var maximum: Double
        var name: String
        var unit: String
        var sequence: Int
        var status: StrictReadDraftStatus

        init(code: String, title: String, label: String, startsAt: Int, maximum: Double, name: String, unit: String, sequence: Int, status: StrictReadDraftStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.startsAt = startsAt
            self.maximum = maximum
            self.name = name
            self.unit = unit
            self.sequence = sequence
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

        func canMoveTo(_ next: StrictReadDraftStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StrictReadDraftStatus.suspended || next == StrictReadDraftStatus.closed
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

        func moveTo(_ next: StrictReadDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict read draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func projectedVolume() -> Double {
            return ((Double(sequence) - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictReadDraft {
            return StrictReadDraft(
                code: code,
                title: title,
                label: label,
                startsAt: startsAt,
                maximum: maximum,
                name: name,
                unit: unit,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict read draft in status draft.
    static func newStrictReadDraft(_ code: String, title: String) -> StrictReadDraft {
        return StrictReadDraft(
            code: code,
            title: title,
            label: "",
            startsAt: 0,
            maximum: 0.0,
            name: "",
            unit: "",
            sequence: 0,
            status: StrictReadDraftStatus.draft
        )
    }
}
