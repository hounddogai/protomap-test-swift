import AcmePlatform
import Foundation

extension Imaging {
    /// Where a regional study draft is in its life cycle.
    enum RegionalStudyDraftStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a regional study draft and its current status.
    final class RegionalStudyDraft {
        var code: String
        var title: String
        var pinned: Bool
        var ward: String
        var segment: String
        var specialty: String
        var priority: Int
        var status: RegionalStudyDraftStatus

        init(code: String, title: String, pinned: Bool, ward: String, segment: String, specialty: String, priority: Int, status: RegionalStudyDraftStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.ward = ward
            self.segment = segment
            self.specialty = specialty
            self.priority = priority
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RegionalStudyDraftStatus) -> Bool {
            switch status {
            case .idle:
                return next == RegionalStudyDraftStatus.ready
            case .warming:
                return next == RegionalStudyDraftStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RegionalStudyDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional study draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(priority)
        }

        func copyValue() -> RegionalStudyDraft {
            return RegionalStudyDraft(
                code: code,
                title: title,
                pinned: pinned,
                ward: ward,
                segment: segment,
                specialty: specialty,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a regional study draft in status idle.
    static func newRegionalStudyDraft(_ code: String, title: String) -> RegionalStudyDraft {
        return RegionalStudyDraft(
            code: code,
            title: title,
            pinned: false,
            ward: "",
            segment: "",
            specialty: "",
            priority: 0,
            status: RegionalStudyDraftStatus.idle
        )
    }
}
