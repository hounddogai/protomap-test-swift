import AcmePlatform
import Foundation

extension Labs {
    /// Where a weighted result request is in its life cycle.
    enum WeightedResultRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted result request. Its code is unique within a tenant.
    final class WeightedResultRequest {
        var code: String
        var label: String
        var ceiling: Double
        var country: String
        var ownerID: String
        var version: Int
        var status: WeightedResultRequestStatus

        init(code: String, label: String, ceiling: Double, country: String, ownerID: String, version: Int, status: WeightedResultRequestStatus) {
            self.code = code
            self.label = label
            self.ceiling = ceiling
            self.country = country
            self.ownerID = ownerID
            self.version = version
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

        func canMoveTo(_ next: WeightedResultRequestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == WeightedResultRequestStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == WeightedResultRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedResultRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted result request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("weighted result request") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(version) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> WeightedResultRequest {
            return WeightedResultRequest(
                code: code,
                label: label,
                ceiling: ceiling,
                country: country,
                ownerID: ownerID,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a weighted result request in status proposed.
    static func newWeightedResultRequest(_ code: String, label: String) -> WeightedResultRequest {
        return WeightedResultRequest(
            code: code,
            label: label,
            ceiling: 0.0,
            country: "",
            ownerID: "",
            version: 0,
            status: WeightedResultRequestStatus.proposed
        )
    }
}
