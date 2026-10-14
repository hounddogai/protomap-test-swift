import AcmePlatform
import Foundation

extension Imaging {
    /// Where a rolling modality assignment is in its life cycle.
    enum RollingModalityAssignmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One rolling modality assignment, with what the planners need to act on it.
    final class RollingModalityAssignment {
        var code: String
        var title: String
        var name: String
        var tags: [String]
        var checksum: String
        var visitMinutes: Int
        var expiresAt: Int
        var status: RollingModalityAssignmentStatus

        init(code: String, title: String, name: String, tags: [String], checksum: String, visitMinutes: Int, expiresAt: Int, status: RollingModalityAssignmentStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.tags = tags
            self.checksum = checksum
            self.visitMinutes = visitMinutes
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RollingModalityAssignmentStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RollingModalityAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling modality assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("rolling modality assignment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func projectedLoad() -> Double {
            return ((Double(visitMinutes) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RollingModalityAssignment {
            return RollingModalityAssignment(
                code: code,
                title: title,
                name: name,
                tags: tags,
                checksum: checksum,
                visitMinutes: visitMinutes,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a rolling modality assignment in status new.
    static func newRollingModalityAssignment(_ code: String, title: String) -> RollingModalityAssignment {
        return RollingModalityAssignment(
            code: code,
            title: title,
            name: "",
            tags: [],
            checksum: "",
            visitMinutes: 0,
            expiresAt: 0,
            status: RollingModalityAssignmentStatus.new
        )
    }
}
