import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a lenient bed board profile is in its life cycle.
    enum LenientBedBoardProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One lenient bed board profile, with what the planners need to act on it.
    final class LenientBedBoardProfile {
        var code: String
        var name: String
        var endsAt: Int
        var createdAt: Int
        var attempts: Int
        var version: Int
        var procedureCode: String
        var status: LenientBedBoardProfileStatus

        init(code: String, name: String, endsAt: Int, createdAt: Int, attempts: Int, version: Int, procedureCode: String, status: LenientBedBoardProfileStatus) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.attempts = attempts
            self.version = version
            self.procedureCode = procedureCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientBedBoardProfileStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LenientBedBoardProfileStatus.reopened || next == LenientBedBoardProfileStatus.archived
            case .reopened:
                return next == LenientBedBoardProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientBedBoardProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient bed board profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(createdAt) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> LenientBedBoardProfile {
            return LenientBedBoardProfile(
                code: code,
                name: name,
                endsAt: endsAt,
                createdAt: createdAt,
                attempts: attempts,
                version: version,
                procedureCode: procedureCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient bed board profile in status open.
    static func newLenientBedBoardProfile(_ code: String, name: String) -> LenientBedBoardProfile {
        return LenientBedBoardProfile(
            code: code,
            name: name,
            endsAt: 0,
            createdAt: 0,
            attempts: 0,
            version: 0,
            procedureCode: "",
            status: LenientBedBoardProfileStatus.`open`
        )
    }
}
