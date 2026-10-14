import AcmePlatform
import Foundation

extension Labs {
    /// Where a result policy is in its life cycle.
    enum ResultPolicyStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A result policy. Its code is unique within a tenant.
    final class ResultPolicy {
        var code: String
        var label: String
        var sequence: Int
        var visitMinutes: Int
        var contactEmail: String
        var windowDays: Int
        var status: ResultPolicyStatus

        init(code: String, label: String, sequence: Int, visitMinutes: Int, contactEmail: String, windowDays: Int, status: ResultPolicyStatus) {
            self.code = code
            self.label = label
            self.sequence = sequence
            self.visitMinutes = visitMinutes
            self.contactEmail = contactEmail
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ResultPolicyStatus) -> Bool {
            switch status {
            case .created:
                return next == ResultPolicyStatus.validated || next == ResultPolicyStatus.published
            case .validated:
                return next == ResultPolicyStatus.published || next == ResultPolicyStatus.retired
            case .published:
                return next == ResultPolicyStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("result policy") \(code)"
        }

        func adjustedLoad() -> Double {
            return ((Double(sequence) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> ResultPolicy {
            return ResultPolicy(
                code: code,
                label: label,
                sequence: sequence,
                visitMinutes: visitMinutes,
                contactEmail: contactEmail,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a result policy in status created.
    static func newResultPolicy(_ code: String, label: String) -> ResultPolicy {
        return ResultPolicy(
            code: code,
            label: label,
            sequence: 0,
            visitMinutes: 0,
            contactEmail: "",
            windowDays: 0,
            status: ResultPolicyStatus.created
        )
    }
}
