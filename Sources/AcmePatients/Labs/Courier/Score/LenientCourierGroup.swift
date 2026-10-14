import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient courier group is in its life cycle.
    enum LenientCourierGroupStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a lenient courier group and its current status.
    final class LenientCourierGroup {
        var code: String
        var title: String
        var bed: String
        var summary: String
        var clinicianID: String
        var pinned: Bool
        var floorValue: Double
        var status: LenientCourierGroupStatus

        init(code: String, title: String, bed: String, summary: String, clinicianID: String, pinned: Bool, floorValue: Double, status: LenientCourierGroupStatus) {
            self.code = code
            self.title = title
            self.bed = bed
            self.summary = summary
            self.clinicianID = clinicianID
            self.pinned = pinned
            self.floorValue = floorValue
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientCourierGroupStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == LenientCourierGroupStatus.done
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LenientCourierGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient courier group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> LenientCourierGroup {
            return LenientCourierGroup(
                code: code,
                title: title,
                bed: bed,
                summary: summary,
                clinicianID: clinicianID,
                pinned: pinned,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient courier group in status new.
    static func newLenientCourierGroup(_ code: String, title: String) -> LenientCourierGroup {
        return LenientCourierGroup(
            code: code,
            title: title,
            bed: "",
            summary: "",
            clinicianID: "",
            pinned: false,
            floorValue: 0.0,
            status: LenientCourierGroupStatus.new
        )
    }
}
