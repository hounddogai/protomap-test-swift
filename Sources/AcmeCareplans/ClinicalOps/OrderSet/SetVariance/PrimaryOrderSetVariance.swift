import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a primary order set variance is in its life cycle.
    enum PrimaryOrderSetVarianceStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One primary order set variance, with what the planners need to act on it.
    final class PrimaryOrderSetVariance {
        var code: String
        var name: String
        var rate: Double
        var channel: String
        var checksum: String
        var threshold: Double
        var facility: String
        var status: PrimaryOrderSetVarianceStatus

        init(code: String, name: String, rate: Double, channel: String, checksum: String, threshold: Double, facility: String, status: PrimaryOrderSetVarianceStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.channel = channel
            self.checksum = checksum
            self.threshold = threshold
            self.facility = facility
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PrimaryOrderSetVarianceStatus) -> Bool {
            switch status {
            case .new:
                return next == PrimaryOrderSetVarianceStatus.queued || next == PrimaryOrderSetVarianceStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == PrimaryOrderSetVarianceStatus.done || next == PrimaryOrderSetVarianceStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: PrimaryOrderSetVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary order set variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedValue() -> Double {
            return ((threshold + rate) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryOrderSetVariance {
            return PrimaryOrderSetVariance(
                code: code,
                name: name,
                rate: rate,
                channel: channel,
                checksum: checksum,
                threshold: threshold,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a primary order set variance in status new.
    static func newPrimaryOrderSetVariance(_ code: String, name: String) -> PrimaryOrderSetVariance {
        return PrimaryOrderSetVariance(
            code: code,
            name: name,
            rate: 0.0,
            channel: "",
            checksum: "",
            threshold: 0.0,
            facility: "",
            status: PrimaryOrderSetVarianceStatus.new
        )
    }
}
