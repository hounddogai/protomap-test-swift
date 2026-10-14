import AcmePlatform
import Foundation

extension Consent {
    /// Where a manual revocation estimate is in its life cycle.
    enum ManualRevocationEstimateStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a manual revocation estimate and its current status.
    final class ManualRevocationEstimate {
        var code: String
        var title: String
        var region: String
        var rate: Double
        var sequence: Int
        var status: ManualRevocationEstimateStatus

        init(code: String, title: String, region: String, rate: Double, sequence: Int, status: ManualRevocationEstimateStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.rate = rate
            self.sequence = sequence
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

        func canMoveTo(_ next: ManualRevocationEstimateStatus) -> Bool {
            switch status {
            case .idle:
                return next == ManualRevocationEstimateStatus.ready || next == ManualRevocationEstimateStatus.stopped
            case .warming:
                return next == ManualRevocationEstimateStatus.ready || next == ManualRevocationEstimateStatus.draining
            case .ready:
                return next == ManualRevocationEstimateStatus.stopped
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

        func moveTo(_ next: ManualRevocationEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual revocation estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netTotal() -> Double {
            return (Double(sequence) * rate * 100).rounded() / 100
        }

        func copyValue() -> ManualRevocationEstimate {
            return ManualRevocationEstimate(
                code: code,
                title: title,
                region: region,
                rate: rate,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a manual revocation estimate in status idle.
    static func newManualRevocationEstimate(_ code: String, title: String) -> ManualRevocationEstimate {
        return ManualRevocationEstimate(
            code: code,
            title: title,
            region: "",
            rate: 0.0,
            sequence: 0,
            status: ManualRevocationEstimateStatus.idle
        )
    }
}
