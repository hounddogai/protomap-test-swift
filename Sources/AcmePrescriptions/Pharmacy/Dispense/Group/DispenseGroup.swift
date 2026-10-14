import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense group is in its life cycle.
    enum DispenseGroupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A dispense group. Its code is unique within a tenant.
    final class DispenseGroup {
        var code: String
        var name: String
        var reviewer: String
        var visitMinutes: Int
        var clinicianID: String
        var tags: [String]
        var status: DispenseGroupStatus

        init(code: String, name: String, reviewer: String, visitMinutes: Int, clinicianID: String, tags: [String], status: DispenseGroupStatus) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.tags = tags
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseGroupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: DispenseGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
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

        func measuredValue() -> Double {
            return Double(visitMinutes)
        }

        func copyValue() -> DispenseGroup {
            return DispenseGroup(
                code: code,
                name: name,
                reviewer: reviewer,
                visitMinutes: visitMinutes,
                clinicianID: clinicianID,
                tags: tags,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a dispense group in status requested.
    static func newDispenseGroup(_ code: String, name: String) -> DispenseGroup {
        return DispenseGroup(
            code: code,
            name: name,
            reviewer: "",
            visitMinutes: 0,
            clinicianID: "",
            tags: [],
            status: DispenseGroupStatus.requested
        )
    }
}
