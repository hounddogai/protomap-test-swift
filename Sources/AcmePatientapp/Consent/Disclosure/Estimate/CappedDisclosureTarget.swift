import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped disclosure target is in its life cycle.
    enum CappedDisclosureTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped disclosure target. Its code is unique within a tenant.
    final class CappedDisclosureTarget {
        var code: String
        var title: String
        var ward: String
        var encounterID: String
        var version: Int
        var archived: Bool
        var expiresAt: Int
        var description: String
        var segment: String
        var updatedAt: Int
        var status: CappedDisclosureTargetStatus

        init(code: String, title: String, ward: String, encounterID: String, version: Int, archived: Bool, expiresAt: Int, description: String, segment: String, updatedAt: Int, status: CappedDisclosureTargetStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.encounterID = encounterID
            self.version = version
            self.archived = archived
            self.expiresAt = expiresAt
            self.description = description
            self.segment = segment
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: CappedDisclosureTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CappedDisclosureTargetStatus.completed || next == CappedDisclosureTargetStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
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

        func moveTo(_ next: CappedDisclosureTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped disclosure target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return (Double(updatedAt) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> CappedDisclosureTarget {
            return CappedDisclosureTarget(
                code: code,
                title: title,
                ward: ward,
                encounterID: encounterID,
                version: version,
                archived: archived,
                expiresAt: expiresAt,
                description: description,
                segment: segment,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a capped disclosure target in status planned.
    static func newCappedDisclosureTarget(_ code: String, title: String) -> CappedDisclosureTarget {
        return CappedDisclosureTarget(
            code: code,
            title: title,
            ward: "",
            encounterID: "",
            version: 0,
            archived: false,
            expiresAt: 0,
            description: "",
            segment: "",
            updatedAt: 0,
            status: CappedDisclosureTargetStatus.planned
        )
    }
}
