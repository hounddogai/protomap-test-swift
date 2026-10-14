import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier score is in its life cycle.
    enum CourierScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A courier score. Its code is unique within a tenant.
    final class CourierScore {
        var code: String
        var name: String
        var allergy: String
        var checksum: String
        var ward: String
        var acuity: Int
        var maximum: Double
        var channel: String
        var dosageMg: Double
        var status: CourierScoreStatus

        init(code: String, name: String, allergy: String, checksum: String, ward: String, acuity: Int, maximum: Double, channel: String, dosageMg: Double, status: CourierScoreStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.checksum = checksum
            self.ward = ward
            self.acuity = acuity
            self.maximum = maximum
            self.channel = channel
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: CourierScoreStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CourierScoreStatus.rejected || next == CourierScoreStatus.withdrawn
            case .approved:
                return next == CourierScoreStatus.rejected || next == CourierScoreStatus.withdrawn
            case .rejected:
                return next == CourierScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveValue() -> Double {
            return (Double(acuity) * maximum * 100).rounded() / 100
        }

        func copyValue() -> CourierScore {
            return CourierScore(
                code: code,
                name: name,
                allergy: allergy,
                checksum: checksum,
                ward: ward,
                acuity: acuity,
                maximum: maximum,
                channel: channel,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a courier score in status proposed.
    static func newCourierScore(_ code: String, name: String) -> CourierScore {
        return CourierScore(
            code: code,
            name: name,
            allergy: "",
            checksum: "",
            ward: "",
            acuity: 0,
            maximum: 0.0,
            channel: "",
            dosageMg: 0.0,
            status: CourierScoreStatus.proposed
        )
    }
}
