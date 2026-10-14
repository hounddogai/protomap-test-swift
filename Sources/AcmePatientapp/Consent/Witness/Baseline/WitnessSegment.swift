import AcmePlatform
import Foundation

extension Consent {
    /// Where a witness segment is in its life cycle.
    enum WitnessSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One witness segment, with what the planners need to act on it.
    final class WitnessSegment {
        var code: String
        var label: String
        var approved: Bool
        var durationMinutes: Int
        var sequence: Int
        var clinicianID: String
        var summary: String
        var discount: Double
        var maximum: Double
        var windowDays: Int
        var tags: [String]
        var status: WitnessSegmentStatus

        init(code: String, label: String, approved: Bool, durationMinutes: Int, sequence: Int, clinicianID: String, summary: String, discount: Double, maximum: Double, windowDays: Int, tags: [String], status: WitnessSegmentStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.durationMinutes = durationMinutes
            self.sequence = sequence
            self.clinicianID = clinicianID
            self.summary = summary
            self.discount = discount
            self.maximum = maximum
            self.windowDays = windowDays
            self.tags = tags
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

        func canMoveTo(_ next: WitnessSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == WitnessSegmentStatus.active
            case .active:
                return next == WitnessSegmentStatus.suspended
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

        func moveTo(_ next: WitnessSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("witness segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func weightedExposure() -> Double {
            return ((Double(windowDays) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> WitnessSegment {
            return WitnessSegment(
                code: code,
                label: label,
                approved: approved,
                durationMinutes: durationMinutes,
                sequence: sequence,
                clinicianID: clinicianID,
                summary: summary,
                discount: discount,
                maximum: maximum,
                windowDays: windowDays,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a witness segment in status draft.
    static func newWitnessSegment(_ code: String, label: String) -> WitnessSegment {
        return WitnessSegment(
            code: code,
            label: label,
            approved: false,
            durationMinutes: 0,
            sequence: 0,
            clinicianID: "",
            summary: "",
            discount: 0.0,
            maximum: 0.0,
            windowDays: 0,
            tags: [],
            status: WitnessSegmentStatus.draft
        )
    }
}
