import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a rolling remittance estimate is in its life cycle.
    enum RollingRemittanceEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A rolling remittance estimate as the remittance team keeps it.
    final class RollingRemittanceEstimate {
        var code: String
        var label: String
        var pinned: Bool
        var rate: Double
        var patientRef: String
        var currency: String
        var refills: Int
        var channel: String
        var status: RollingRemittanceEstimateStatus

        init(code: String, label: String, pinned: Bool, rate: Double, patientRef: String, currency: String, refills: Int, channel: String, status: RollingRemittanceEstimateStatus) {
            self.code = code
            self.label = label
            self.pinned = pinned
            self.rate = rate
            self.patientRef = patientRef
            self.currency = currency
            self.refills = refills
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingRemittanceEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == RollingRemittanceEstimateStatus.warming
            case .warming:
                return next == RollingRemittanceEstimateStatus.ready || next == RollingRemittanceEstimateStatus.stopped
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: RollingRemittanceEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling remittance estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("rolling remittance estimate") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(refills) + rate) * 100).rounded() / 100
        }

        func copyValue() -> RollingRemittanceEstimate {
            return RollingRemittanceEstimate(
                code: code,
                label: label,
                pinned: pinned,
                rate: rate,
                patientRef: patientRef,
                currency: currency,
                refills: refills,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling remittance estimate in status idle.
    static func newRollingRemittanceEstimate(_ code: String, label: String) -> RollingRemittanceEstimate {
        return RollingRemittanceEstimate(
            code: code,
            label: label,
            pinned: false,
            rate: 0.0,
            patientRef: "",
            currency: "",
            refills: 0,
            channel: "",
            status: RollingRemittanceEstimateStatus.idle
        )
    }
}
