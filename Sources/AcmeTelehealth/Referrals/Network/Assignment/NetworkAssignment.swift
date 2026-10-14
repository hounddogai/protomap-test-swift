import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network assignment is in its life cycle.
    enum NetworkAssignmentStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One network assignment, with what the planners need to act on it.
    final class NetworkAssignment {
        var code: String
        var label: String
        var source: String
        var timezone: String
        var floorValue: Double
        var refills: Int
        var status: NetworkAssignmentStatus

        init(code: String, label: String, source: String, timezone: String, floorValue: Double, refills: Int, status: NetworkAssignmentStatus) {
            self.code = code
            self.label = label
            self.source = source
            self.timezone = timezone
            self.floorValue = floorValue
            self.refills = refills
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

        func canMoveTo(_ next: NetworkAssignmentStatus) -> Bool {
            switch status {
            case .proposed:
                return next == NetworkAssignmentStatus.approved || next == NetworkAssignmentStatus.withdrawn
            case .approved:
                return next == NetworkAssignmentStatus.rejected
            case .rejected:
                return next == NetworkAssignmentStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return (Double(refills) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> NetworkAssignment {
            return NetworkAssignment(
                code: code,
                label: label,
                source: source,
                timezone: timezone,
                floorValue: floorValue,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a network assignment in status proposed.
    static func newNetworkAssignment(_ code: String, label: String) -> NetworkAssignment {
        return NetworkAssignment(
            code: code,
            label: label,
            source: "",
            timezone: "",
            floorValue: 0.0,
            refills: 0,
            status: NetworkAssignmentStatus.proposed
        )
    }
}
