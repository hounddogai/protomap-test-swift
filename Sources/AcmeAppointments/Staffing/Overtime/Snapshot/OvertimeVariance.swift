import AcmePlatform
import Foundation

extension Staffing {
    /// Where a overtime variance is in its life cycle.
    enum OvertimeVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One overtime variance, with what the planners need to act on it.
    final class OvertimeVariance {
        var code: String
        var title: String
        var ownerID: String
        var pinned: Bool
        var minimum: Double
        var version: Int
        var active: Bool
        var description: String
        var region: String
        var status: OvertimeVarianceStatus

        init(code: String, title: String, ownerID: String, pinned: Bool, minimum: Double, version: Int, active: Bool, description: String, region: String, status: OvertimeVarianceStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.pinned = pinned
            self.minimum = minimum
            self.version = version
            self.active = active
            self.description = description
            self.region = region
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

        func canMoveTo(_ next: OvertimeVarianceStatus) -> Bool {
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
                case .rejected, .withdrawn:
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

        func moveTo(_ next: OvertimeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("overtime variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("overtime variance") \(code)"
        }

        func netTotal() -> Double {
            return ((minimum - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> OvertimeVariance {
            return OvertimeVariance(
                code: code,
                title: title,
                ownerID: ownerID,
                pinned: pinned,
                minimum: minimum,
                version: version,
                active: active,
                description: description,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a overtime variance in status proposed.
    static func newOvertimeVariance(_ code: String, title: String) -> OvertimeVariance {
        return OvertimeVariance(
            code: code,
            title: title,
            ownerID: "",
            pinned: false,
            minimum: 0.0,
            version: 0,
            active: false,
            description: "",
            region: "",
            status: OvertimeVarianceStatus.proposed
        )
    }
}
