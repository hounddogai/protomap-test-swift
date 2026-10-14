import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form window is in its life cycle.
    enum ConsentFormWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a consent form window and its current status.
    final class ConsentFormWindow {
        var code: String
        var label: String
        var floorValue: Double
        var acuity: Int
        var sequence: Int
        var maximum: Double
        var active: Bool
        var rate: Double
        var margin: Double
        var status: ConsentFormWindowStatus

        init(code: String, label: String, floorValue: Double, acuity: Int, sequence: Int, maximum: Double, active: Bool, rate: Double, margin: Double, status: ConsentFormWindowStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.acuity = acuity
            self.sequence = sequence
            self.maximum = maximum
            self.active = active
            self.rate = rate
            self.margin = margin
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

        func canMoveTo(_ next: ConsentFormWindowStatus) -> Bool {
            switch status {
            case .idle:
                return next == ConsentFormWindowStatus.ready || next == ConsentFormWindowStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ConsentFormWindowStatus.stopped
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

        func moveTo(_ next: ConsentFormWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedLoad() -> Double {
            return ((maximum - margin) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormWindow {
            return ConsentFormWindow(
                code: code,
                label: label,
                floorValue: floorValue,
                acuity: acuity,
                sequence: sequence,
                maximum: maximum,
                active: active,
                rate: rate,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a consent form window in status idle.
    static func newConsentFormWindow(_ code: String, label: String) -> ConsentFormWindow {
        return ConsentFormWindow(
            code: code,
            label: label,
            floorValue: 0.0,
            acuity: 0,
            sequence: 0,
            maximum: 0.0,
            active: false,
            rate: 0.0,
            margin: 0.0,
            status: ConsentFormWindowStatus.idle
        )
    }
}
