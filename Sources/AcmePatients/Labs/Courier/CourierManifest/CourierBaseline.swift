import AcmePlatform
import Foundation

extension Labs {
    /// Where a courier baseline is in its life cycle.
    enum CourierBaselineStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A courier baseline. Its code is unique within a tenant.
    final class CourierBaseline {
        var code: String
        var name: String
        var retries: Int
        var copay: Double
        var visible: Bool
        var threshold: Double
        var acuity: Int
        var status: CourierBaselineStatus

        init(code: String, name: String, retries: Int, copay: Double, visible: Bool, threshold: Double, acuity: Int, status: CourierBaselineStatus) {
            self.code = code
            self.name = name
            self.retries = retries
            self.copay = copay
            self.visible = visible
            self.threshold = threshold
            self.acuity = acuity
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

        func canMoveTo(_ next: CourierBaselineStatus) -> Bool {
            switch status {
            case .idle:
                return next == CourierBaselineStatus.ready || next == CourierBaselineStatus.draining
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == CourierBaselineStatus.draining || next == CourierBaselineStatus.stopped
            case .draining:
                return next == CourierBaselineStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CourierBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("courier baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveExposure() -> Double {
            return ((Double(retries) + copay) * 100).rounded() / 100
        }

        func copyValue() -> CourierBaseline {
            return CourierBaseline(
                code: code,
                name: name,
                retries: retries,
                copay: copay,
                visible: visible,
                threshold: threshold,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a courier baseline in status idle.
    static func newCourierBaseline(_ code: String, name: String) -> CourierBaseline {
        return CourierBaseline(
            code: code,
            name: name,
            retries: 0,
            copay: 0.0,
            visible: false,
            threshold: 0.0,
            acuity: 0,
            status: CourierBaselineStatus.idle
        )
    }
}
