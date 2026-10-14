import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary order set estimate is in its life cycle.
    enum PrimaryOrderSetEstimateStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary order set estimate, with what the planners need to act on it.
    final class PrimaryOrderSetEstimate {
        var code: String
        var title: String
        var contactEmail: String
        var limit: Int
        var amount: Double
        var patientRef: String
        var capacity: Int
        var diagnosisCode: String
        var channel: String
        var maximum: Double
        var visitMinutes: Int
        var status: PrimaryOrderSetEstimateStatus

        init(code: String, title: String, contactEmail: String, limit: Int, amount: Double, patientRef: String, capacity: Int, diagnosisCode: String, channel: String, maximum: Double, visitMinutes: Int, status: PrimaryOrderSetEstimateStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.limit = limit
            self.amount = amount
            self.patientRef = patientRef
            self.capacity = capacity
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.maximum = maximum
            self.visitMinutes = visitMinutes
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

        func canMoveTo(_ next: PrimaryOrderSetEstimateStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == PrimaryOrderSetEstimateStatus.revoked
            case .revoked:
                return next == PrimaryOrderSetEstimateStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryOrderSetEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary order set estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netLoad() -> Double {
            return ((Double(capacity) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOrderSetEstimate {
            return PrimaryOrderSetEstimate(
                code: code,
                title: title,
                contactEmail: contactEmail,
                limit: limit,
                amount: amount,
                patientRef: patientRef,
                capacity: capacity,
                diagnosisCode: diagnosisCode,
                channel: channel,
                maximum: maximum,
                visitMinutes: visitMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary order set estimate in status requested.
    static func newPrimaryOrderSetEstimate(_ code: String, title: String) -> PrimaryOrderSetEstimate {
        return PrimaryOrderSetEstimate(
            code: code,
            title: title,
            contactEmail: "",
            limit: 0,
            amount: 0.0,
            patientRef: "",
            capacity: 0,
            diagnosisCode: "",
            channel: "",
            maximum: 0.0,
            visitMinutes: 0,
            status: PrimaryOrderSetEstimateStatus.requested
        )
    }
}
