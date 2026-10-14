import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a census policy is in its life cycle.
    enum CensusPolicyStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A census policy. Its code is unique within a tenant.
    final class CensusPolicy {
        var code: String
        var name: String
        var windowDays: Int
        var maximum: Double
        var limit: Int
        var approved: Bool
        var status: CensusPolicyStatus

        init(code: String, name: String, windowDays: Int, maximum: Double, limit: Int, approved: Bool, status: CensusPolicyStatus) {
            self.code = code
            self.name = name
            self.windowDays = windowDays
            self.maximum = maximum
            self.limit = limit
            self.approved = approved
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

        func canMoveTo(_ next: CensusPolicyStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == CensusPolicyStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CensusPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("census policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((Double(limit) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> CensusPolicy {
            return CensusPolicy(
                code: code,
                name: name,
                windowDays: windowDays,
                maximum: maximum,
                limit: limit,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a census policy in status requested.
    static func newCensusPolicy(_ code: String, name: String) -> CensusPolicy {
        return CensusPolicy(
            code: code,
            name: name,
            windowDays: 0,
            maximum: 0.0,
            limit: 0,
            approved: false,
            status: CensusPolicyStatus.requested
        )
    }
}
