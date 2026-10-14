import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient read mapping is in its life cycle.
    enum LenientReadMappingStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient read mapping, with what the planners need to act on it.
    final class LenientReadMapping {
        var code: String
        var name: String
        var limit: Int
        var graceDays: Int
        var specialty: String
        var ownerID: String
        var description: String
        var region: String
        var pinned: Bool
        var status: LenientReadMappingStatus

        init(code: String, name: String, limit: Int, graceDays: Int, specialty: String, ownerID: String, description: String, region: String, pinned: Bool, status: LenientReadMappingStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.graceDays = graceDays
            self.specialty = specialty
            self.ownerID = ownerID
            self.description = description
            self.region = region
            self.pinned = pinned
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientReadMappingStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: LenientReadMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient read mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func effectiveTotal() -> Double {
            return ((Double(limit) - Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> LenientReadMapping {
            return LenientReadMapping(
                code: code,
                name: name,
                limit: limit,
                graceDays: graceDays,
                specialty: specialty,
                ownerID: ownerID,
                description: description,
                region: region,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient read mapping in status proposed.
    static func newLenientReadMapping(_ code: String, name: String) -> LenientReadMapping {
        return LenientReadMapping(
            code: code,
            name: name,
            limit: 0,
            graceDays: 0,
            specialty: "",
            ownerID: "",
            description: "",
            region: "",
            pinned: false,
            status: LenientReadMappingStatus.proposed
        )
    }
}
