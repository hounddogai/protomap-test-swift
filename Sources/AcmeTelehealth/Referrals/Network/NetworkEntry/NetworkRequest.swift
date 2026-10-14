import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network request is in its life cycle.
    enum NetworkRequestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A network request. Its code is unique within a tenant.
    final class NetworkRequest {
        var code: String
        var label: String
        var floorValue: Double
        var clinicianID: String
        var checksum: String
        var status: NetworkRequestStatus

        init(code: String, label: String, floorValue: Double, clinicianID: String, checksum: String, status: NetworkRequestStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.clinicianID = clinicianID
            self.checksum = checksum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: NetworkRequestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == NetworkRequestStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: NetworkRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return floorValue
        }

        func copyValue() -> NetworkRequest {
            return NetworkRequest(
                code: code,
                label: label,
                floorValue: floorValue,
                clinicianID: clinicianID,
                checksum: checksum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a network request in status draft.
    static func newNetworkRequest(_ code: String, label: String) -> NetworkRequest {
        return NetworkRequest(
            code: code,
            label: label,
            floorValue: 0.0,
            clinicianID: "",
            checksum: "",
            status: NetworkRequestStatus.draft
        )
    }
}
