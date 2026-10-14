import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read allocation is in its life cycle.
    enum ReadAllocationStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One read allocation, with what the planners need to act on it.
    final class ReadAllocation {
        var code: String
        var name: String
        var country: String
        var acuity: Int
        var active: Bool
        var version: Int
        var copay: Double
        var description: String
        var status: ReadAllocationStatus

        init(code: String, name: String, country: String, acuity: Int, active: Bool, version: Int, copay: Double, description: String, status: ReadAllocationStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.acuity = acuity
            self.active = active
            self.version = version
            self.copay = copay
            self.description = description
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

        func canMoveTo(_ next: ReadAllocationStatus) -> Bool {
            switch status {
            case .requested:
                return next == ReadAllocationStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ReadAllocationStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("read allocation") \(code)"
        }

        func netLoad() -> Double {
            return (Double(acuity) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> ReadAllocation {
            return ReadAllocation(
                code: code,
                name: name,
                country: country,
                acuity: acuity,
                active: active,
                version: version,
                copay: copay,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a read allocation in status requested.
    static func newReadAllocation(_ code: String, name: String) -> ReadAllocation {
        return ReadAllocation(
            code: code,
            name: name,
            country: "",
            acuity: 0,
            active: false,
            version: 0,
            copay: 0.0,
            description: "",
            status: ReadAllocationStatus.requested
        )
    }
}
