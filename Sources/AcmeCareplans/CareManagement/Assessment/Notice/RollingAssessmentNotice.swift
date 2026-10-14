import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling assessment notice is in its life cycle.
    enum RollingAssessmentNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a rolling assessment notice and its current status.
    final class RollingAssessmentNotice {
        var code: String
        var title: String
        var tags: [String]
        var ward: String
        var version: Int
        var status: RollingAssessmentNoticeStatus

        init(code: String, title: String, tags: [String], ward: String, version: Int, status: RollingAssessmentNoticeStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.ward = ward
            self.version = version
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingAssessmentNoticeStatus) -> Bool {
            switch status {
            case .created:
                return next == RollingAssessmentNoticeStatus.retired
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: RollingAssessmentNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling assessment notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
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
            return Double(version)
        }

        func copyValue() -> RollingAssessmentNotice {
            return RollingAssessmentNotice(
                code: code,
                title: title,
                tags: tags,
                ward: ward,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a rolling assessment notice in status created.
    static func newRollingAssessmentNotice(_ code: String, title: String) -> RollingAssessmentNotice {
        return RollingAssessmentNotice(
            code: code,
            title: title,
            tags: [],
            ward: "",
            version: 0,
            status: RollingAssessmentNoticeStatus.created
        )
    }
}
