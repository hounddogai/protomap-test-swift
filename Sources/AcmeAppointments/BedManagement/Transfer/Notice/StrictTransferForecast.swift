import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict transfer forecast is in its life cycle.
    enum StrictTransferForecastStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict transfer forecast as the transfer team keeps it.
    final class StrictTransferForecast {
        var code: String
        var label: String
        var floorValue: Double
        var pinned: Bool
        var currency: String
        var minimum: Double
        var capacity: Int
        var payer: String
        var status: StrictTransferForecastStatus

        init(code: String, label: String, floorValue: Double, pinned: Bool, currency: String, minimum: Double, capacity: Int, payer: String, status: StrictTransferForecastStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.pinned = pinned
            self.currency = currency
            self.minimum = minimum
            self.capacity = capacity
            self.payer = payer
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

        func canMoveTo(_ next: StrictTransferForecastStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: StrictTransferForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict transfer forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func weightedLoad() -> Double {
            return (Double(capacity) * minimum * 100).rounded() / 100
        }

        func copyValue() -> StrictTransferForecast {
            return StrictTransferForecast(
                code: code,
                label: label,
                floorValue: floorValue,
                pinned: pinned,
                currency: currency,
                minimum: minimum,
                capacity: capacity,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict transfer forecast in status new.
    static func newStrictTransferForecast(_ code: String, label: String) -> StrictTransferForecast {
        return StrictTransferForecast(
            code: code,
            label: label,
            floorValue: 0.0,
            pinned: false,
            currency: "",
            minimum: 0.0,
            capacity: 0,
            payer: "",
            status: StrictTransferForecastStatus.new
        )
    }
}
