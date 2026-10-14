import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a capped order set exception is in its life cycle.
    enum CappedOrderSetExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped order set exception as the order set team keeps it.
    final class CappedOrderSetException {
        var code: String
        var label: String
        var durationMinutes: Int
        var rate: Double
        var channel: String
        var unit: String
        var status: CappedOrderSetExceptionStatus

        init(code: String, label: String, durationMinutes: Int, rate: Double, channel: String, unit: String, status: CappedOrderSetExceptionStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.rate = rate
            self.channel = channel
            self.unit = unit
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedOrderSetExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == CappedOrderSetExceptionStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: CappedOrderSetExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped order set exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("capped order set exception") \(code)"
        }

        func projectedVolume() -> Double {
            return ((rate - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> CappedOrderSetException {
            return CappedOrderSetException(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                rate: rate,
                channel: channel,
                unit: unit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a capped order set exception in status created.
    static func newCappedOrderSetException(_ code: String, label: String) -> CappedOrderSetException {
        return CappedOrderSetException(
            code: code,
            label: label,
            durationMinutes: 0,
            rate: 0.0,
            channel: "",
            unit: "",
            status: CappedOrderSetExceptionStatus.created
        )
    }
}
