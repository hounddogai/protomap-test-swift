import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool digest is in its life cycle.
    enum FloatPoolDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One float pool digest, with what the planners need to act on it.
    final class FloatPoolDigest {
        var code: String
        var label: String
        var minimum: Double
        var attempts: Int
        var description: String
        var amount: Double
        var discount: Double
        var status: FloatPoolDigestStatus

        init(code: String, label: String, minimum: Double, attempts: Int, description: String, amount: Double, discount: Double, status: FloatPoolDigestStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.attempts = attempts
            self.description = description
            self.amount = amount
            self.discount = discount
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

        func canMoveTo(_ next: FloatPoolDigestStatus) -> Bool {
            switch status {
            case .new:
                return next == FloatPoolDigestStatus.running
            case .queued:
                return next == FloatPoolDigestStatus.running || next == FloatPoolDigestStatus.done
            case .running:
                return next == FloatPoolDigestStatus.done || next == FloatPoolDigestStatus.failed
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

        func moveTo(_ next: FloatPoolDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func adjustedValue() -> Double {
            return ((minimum - amount) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolDigest {
            return FloatPoolDigest(
                code: code,
                label: label,
                minimum: minimum,
                attempts: attempts,
                description: description,
                amount: amount,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool digest in status new.
    static func newFloatPoolDigest(_ code: String, label: String) -> FloatPoolDigest {
        return FloatPoolDigest(
            code: code,
            label: label,
            minimum: 0.0,
            attempts: 0,
            description: "",
            amount: 0.0,
            discount: 0.0,
            status: FloatPoolDigestStatus.new
        )
    }
}
