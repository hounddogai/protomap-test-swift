import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a capped bed board group is in its life cycle.
    enum CappedBedBoardGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped bed board group as the bed board team keeps it.
    final class CappedBedBoardGroup {
        var code: String
        var label: String
        var tags: [String]
        var title: String
        var active: Bool
        var maximum: Double
        var channel: String
        var ward: String
        var segment: String
        var attempts: Int
        var status: CappedBedBoardGroupStatus

        init(code: String, label: String, tags: [String], title: String, active: Bool, maximum: Double, channel: String, ward: String, segment: String, attempts: Int, status: CappedBedBoardGroupStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.title = title
            self.active = active
            self.maximum = maximum
            self.channel = channel
            self.ward = ward
            self.segment = segment
            self.attempts = attempts
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

        func canMoveTo(_ next: CappedBedBoardGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == CappedBedBoardGroupStatus.scheduled
            case .scheduled:
                return next == CappedBedBoardGroupStatus.completed || next == CappedBedBoardGroupStatus.cancelled
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: CappedBedBoardGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped bed board group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped bed board group") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return ((Double(attempts) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CappedBedBoardGroup {
            return CappedBedBoardGroup(
                code: code,
                label: label,
                tags: tags,
                title: title,
                active: active,
                maximum: maximum,
                channel: channel,
                ward: ward,
                segment: segment,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped bed board group in status planned.
    static func newCappedBedBoardGroup(_ code: String, label: String) -> CappedBedBoardGroup {
        return CappedBedBoardGroup(
            code: code,
            label: label,
            tags: [],
            title: "",
            active: false,
            maximum: 0.0,
            channel: "",
            ward: "",
            segment: "",
            attempts: 0,
            status: CappedBedBoardGroupStatus.planned
        )
    }
}
