import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive program exception is in its life cycle.
    enum AdaptiveProgramExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One adaptive program exception, with what the planners need to act on it.
    final class AdaptiveProgramException {
        var code: String
        var title: String
        var externalRef: String
        var acuity: Int
        var amount: Double
        var name: String
        var status: AdaptiveProgramExceptionStatus

        init(code: String, title: String, externalRef: String, acuity: Int, amount: Double, name: String, status: AdaptiveProgramExceptionStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.acuity = acuity
            self.amount = amount
            self.name = name
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

        func canMoveTo(_ next: AdaptiveProgramExceptionStatus) -> Bool {
            switch status {
            case .idle:
                return next == AdaptiveProgramExceptionStatus.warming || next == AdaptiveProgramExceptionStatus.ready
            case .warming:
                return next == AdaptiveProgramExceptionStatus.ready || next == AdaptiveProgramExceptionStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == AdaptiveProgramExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveProgramExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive program exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedVolume() -> Double {
            return (amount * Double(acuity) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveProgramException {
            return AdaptiveProgramException(
                code: code,
                title: title,
                externalRef: externalRef,
                acuity: acuity,
                amount: amount,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive program exception in status idle.
    static func newAdaptiveProgramException(_ code: String, title: String) -> AdaptiveProgramException {
        return AdaptiveProgramException(
            code: code,
            title: title,
            externalRef: "",
            acuity: 0,
            amount: 0.0,
            name: "",
            status: AdaptiveProgramExceptionStatus.idle
        )
    }
}
