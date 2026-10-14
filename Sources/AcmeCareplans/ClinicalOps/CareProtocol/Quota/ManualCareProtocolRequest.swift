import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a manual care protocol request is in its life cycle.
    enum ManualCareProtocolRequestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a manual care protocol request and its current status.
    final class ManualCareProtocolRequest {
        var code: String
        var name: String
        var ratio: Double
        var currency: String
        var summary: String
        var dosageMg: Double
        var maximum: Double
        var payer: String
        var channel: String
        var status: ManualCareProtocolRequestStatus

        init(code: String, name: String, ratio: Double, currency: String, summary: String, dosageMg: Double, maximum: Double, payer: String, channel: String, status: ManualCareProtocolRequestStatus) {
            self.code = code
            self.name = name
            self.ratio = ratio
            self.currency = currency
            self.summary = summary
            self.dosageMg = dosageMg
            self.maximum = maximum
            self.payer = payer
            self.channel = channel
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

        func canMoveTo(_ next: ManualCareProtocolRequestStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .withdrawn:
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
                return next == ManualCareProtocolRequestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualCareProtocolRequestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual care protocol request \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("manual care protocol request") \(code)"
        }

        func projectedLoad() -> Double {
            return (maximum * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> ManualCareProtocolRequest {
            return ManualCareProtocolRequest(
                code: code,
                name: name,
                ratio: ratio,
                currency: currency,
                summary: summary,
                dosageMg: dosageMg,
                maximum: maximum,
                payer: payer,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual care protocol request in status proposed.
    static func newManualCareProtocolRequest(_ code: String, name: String) -> ManualCareProtocolRequest {
        return ManualCareProtocolRequest(
            code: code,
            name: name,
            ratio: 0.0,
            currency: "",
            summary: "",
            dosageMg: 0.0,
            maximum: 0.0,
            payer: "",
            channel: "",
            status: ManualCareProtocolRequestStatus.proposed
        )
    }
}
