import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy record is in its life cycle.
    enum ProxyRecordStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A proxy record as the proxy team keeps it.
    final class ProxyRecord {
        var code: String
        var name: String
        var visitMinutes: Int
        var graceDays: Int
        var acuity: Int
        var clinicianID: String
        var floorValue: Double
        var budget: Double
        var status: ProxyRecordStatus

        init(code: String, name: String, visitMinutes: Int, graceDays: Int, acuity: Int, clinicianID: String, floorValue: Double, budget: Double, status: ProxyRecordStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.acuity = acuity
            self.clinicianID = clinicianID
            self.floorValue = floorValue
            self.budget = budget
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

        func canMoveTo(_ next: ProxyRecordStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .rejected:
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
                return next == ProxyRecordStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveTotal() -> Double {
            return ((Double(visitMinutes) + budget) * 100).rounded() / 100
        }

        func copyValue() -> ProxyRecord {
            return ProxyRecord(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                acuity: acuity,
                clinicianID: clinicianID,
                floorValue: floorValue,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a proxy record in status proposed.
    static func newProxyRecord(_ code: String, name: String) -> ProxyRecord {
        return ProxyRecord(
            code: code,
            name: name,
            visitMinutes: 0,
            graceDays: 0,
            acuity: 0,
            clinicianID: "",
            floorValue: 0.0,
            budget: 0.0,
            status: ProxyRecordStatus.proposed
        )
    }
}
