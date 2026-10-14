import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched formulary policy is in its life cycle.
    enum BatchedFormularyPolicyStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One batched formulary policy, with what the planners need to act on it.
    final class BatchedFormularyPolicy {
        var code: String
        var title: String
        var country: String
        var ward: String
        var label: String
        var graceDays: Int
        var status: BatchedFormularyPolicyStatus

        init(code: String, title: String, country: String, ward: String, label: String, graceDays: Int, status: BatchedFormularyPolicyStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.ward = ward
            self.label = label
            self.graceDays = graceDays
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

        func canMoveTo(_ next: BatchedFormularyPolicyStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BatchedFormularyPolicyStatus.draining
            case .draining:
                return next == BatchedFormularyPolicyStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedFormularyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched formulary policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("batched formulary policy") \(code)"
        }

        func measuredValue() -> Double {
            return Double(graceDays)
        }

        func copyValue() -> BatchedFormularyPolicy {
            return BatchedFormularyPolicy(
                code: code,
                title: title,
                country: country,
                ward: ward,
                label: label,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a batched formulary policy in status idle.
    static func newBatchedFormularyPolicy(_ code: String, title: String) -> BatchedFormularyPolicy {
        return BatchedFormularyPolicy(
            code: code,
            title: title,
            country: "",
            ward: "",
            label: "",
            graceDays: 0,
            status: BatchedFormularyPolicyStatus.idle
        )
    }
}
