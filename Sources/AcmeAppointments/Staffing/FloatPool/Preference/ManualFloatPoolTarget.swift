import AcmePlatform
import Foundation

extension Staffing {
    /// Where a manual float pool target is in its life cycle.
    enum ManualFloatPoolTargetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A manual float pool target. Its code is unique within a tenant.
    final class ManualFloatPoolTarget {
        var code: String
        var name: String
        var procedureCode: String
        var capacity: Int
        var rate: Double
        var region: String
        var limit: Int
        var contactEmail: String
        var graceDays: Int
        var status: ManualFloatPoolTargetStatus

        init(code: String, name: String, procedureCode: String, capacity: Int, rate: Double, region: String, limit: Int, contactEmail: String, graceDays: Int, status: ManualFloatPoolTargetStatus) {
            self.code = code
            self.name = name
            self.procedureCode = procedureCode
            self.capacity = capacity
            self.rate = rate
            self.region = region
            self.limit = limit
            self.contactEmail = contactEmail
            self.graceDays = graceDays
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

        func canMoveTo(_ next: ManualFloatPoolTargetStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ManualFloatPoolTargetStatus.approved
            case .approved:
                return next == ManualFloatPoolTargetStatus.rejected
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

        func moveTo(_ next: ManualFloatPoolTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual float pool target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(capacity) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> ManualFloatPoolTarget {
            return ManualFloatPoolTarget(
                code: code,
                name: name,
                procedureCode: procedureCode,
                capacity: capacity,
                rate: rate,
                region: region,
                limit: limit,
                contactEmail: contactEmail,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual float pool target in status proposed.
    static func newManualFloatPoolTarget(_ code: String, name: String) -> ManualFloatPoolTarget {
        return ManualFloatPoolTarget(
            code: code,
            name: name,
            procedureCode: "",
            capacity: 0,
            rate: 0.0,
            region: "",
            limit: 0,
            contactEmail: "",
            graceDays: 0,
            status: ManualFloatPoolTargetStatus.proposed
        )
    }
}
