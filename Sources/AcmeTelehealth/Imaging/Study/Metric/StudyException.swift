import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study exception is in its life cycle.
    enum StudyExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A study exception. Its code is unique within a tenant.
    final class StudyException {
        var code: String
        var name: String
        var pinned: Bool
        var ratio: Double
        var country: String
        var windowDays: Int
        var graceDays: Int
        var tags: [String]
        var title: String
        var status: StudyExceptionStatus

        init(code: String, name: String, pinned: Bool, ratio: Double, country: String, windowDays: Int, graceDays: Int, tags: [String], title: String, status: StudyExceptionStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.ratio = ratio
            self.country = country
            self.windowDays = windowDays
            self.graceDays = graceDays
            self.tags = tags
            self.title = title
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

        func canMoveTo(_ next: StudyExceptionStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == StudyExceptionStatus.active || next == StudyExceptionStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StudyExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netValue() -> Double {
            return ((Double(windowDays) + ratio) * 100).rounded() / 100
        }

        func copyValue() -> StudyException {
            return StudyException(
                code: code,
                name: name,
                pinned: pinned,
                ratio: ratio,
                country: country,
                windowDays: windowDays,
                graceDays: graceDays,
                tags: tags,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a study exception in status draft.
    static func newStudyException(_ code: String, name: String) -> StudyException {
        return StudyException(
            code: code,
            name: name,
            pinned: false,
            ratio: 0.0,
            country: "",
            windowDays: 0,
            graceDays: 0,
            tags: [],
            title: "",
            status: StudyExceptionStatus.draft
        )
    }
}
