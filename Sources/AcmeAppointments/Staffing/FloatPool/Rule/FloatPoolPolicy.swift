import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool policy is in its life cycle.
    enum FloatPoolPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a float pool policy and its current status.
    final class FloatPoolPolicy {
        var code: String
        var label: String
        var revision: Int
        var margin: Double
        var name: String
        var status: FloatPoolPolicyStatus

        init(code: String, label: String, revision: Int, margin: Double, name: String, status: FloatPoolPolicyStatus) {
            self.code = code
            self.label = label
            self.revision = revision
            self.margin = margin
            self.name = name
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

        func canMoveTo(_ next: FloatPoolPolicyStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FloatPoolPolicyStatus.published || next == FloatPoolPolicyStatus.retired
            case .published:
                return next == FloatPoolPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func adjustedLoad() -> Double {
            return (Double(revision) * margin * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolPolicy {
            return FloatPoolPolicy(
                code: code,
                label: label,
                revision: revision,
                margin: margin,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a float pool policy in status created.
    static func newFloatPoolPolicy(_ code: String, label: String) -> FloatPoolPolicy {
        return FloatPoolPolicy(
            code: code,
            label: label,
            revision: 0,
            margin: 0.0,
            name: "",
            status: FloatPoolPolicyStatus.created
        )
    }
}
