import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient dispense metric is in its life cycle.
    enum LenientDispenseMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One lenient dispense metric, with what the planners need to act on it.
    final class LenientDispenseMetric {
        var code: String
        var name: String
        var limit: Int
        var country: String
        var approved: Bool
        var checksum: String
        var channel: String
        var ownerID: String
        var amount: Double
        var dosageMg: Double
        var encounterID: String
        var status: LenientDispenseMetricStatus

        init(code: String, name: String, limit: Int, country: String, approved: Bool, checksum: String, channel: String, ownerID: String, amount: Double, dosageMg: Double, encounterID: String, status: LenientDispenseMetricStatus) {
            self.code = code
            self.name = name
            self.limit = limit
            self.country = country
            self.approved = approved
            self.checksum = checksum
            self.channel = channel
            self.ownerID = ownerID
            self.amount = amount
            self.dosageMg = dosageMg
            self.encounterID = encounterID
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

        func canMoveTo(_ next: LenientDispenseMetricStatus) -> Bool {
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
                return next == LenientDispenseMetricStatus.rejected || next == LenientDispenseMetricStatus.withdrawn
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

        func moveTo(_ next: LenientDispenseMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient dispense metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netLoad() -> Double {
            return ((Double(limit) - dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LenientDispenseMetric {
            return LenientDispenseMetric(
                code: code,
                name: name,
                limit: limit,
                country: country,
                approved: approved,
                checksum: checksum,
                channel: channel,
                ownerID: ownerID,
                amount: amount,
                dosageMg: dosageMg,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a lenient dispense metric in status proposed.
    static func newLenientDispenseMetric(_ code: String, name: String) -> LenientDispenseMetric {
        return LenientDispenseMetric(
            code: code,
            name: name,
            limit: 0,
            country: "",
            approved: false,
            checksum: "",
            channel: "",
            ownerID: "",
            amount: 0.0,
            dosageMg: 0.0,
            encounterID: "",
            status: LenientDispenseMetricStatus.proposed
        )
    }
}
