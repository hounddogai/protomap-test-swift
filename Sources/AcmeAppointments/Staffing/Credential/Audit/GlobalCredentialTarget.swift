import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global credential target is in its life cycle.
    enum GlobalCredentialTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One global credential target, with what the planners need to act on it.
    final class GlobalCredentialTarget {
        var code: String
        var name: String
        var updatedAt: Int
        var budget: Double
        var retries: Int
        var currency: String
        var windowDays: Int
        var score: Double
        var discount: Double
        var diagnosisCode: String
        var status: GlobalCredentialTargetStatus

        init(code: String, name: String, updatedAt: Int, budget: Double, retries: Int, currency: String, windowDays: Int, score: Double, discount: Double, diagnosisCode: String, status: GlobalCredentialTargetStatus) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.budget = budget
            self.retries = retries
            self.currency = currency
            self.windowDays = windowDays
            self.score = score
            self.discount = discount
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: GlobalCredentialTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == GlobalCredentialTargetStatus.ready || next == GlobalCredentialTargetStatus.stopped
            case .ready:
                return next == GlobalCredentialTargetStatus.draining
            case .draining:
                return next == GlobalCredentialTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalCredentialTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global credential target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedTotal() -> Double {
            return (score * budget * 100).rounded() / 100
        }

        func copyValue() -> GlobalCredentialTarget {
            return GlobalCredentialTarget(
                code: code,
                name: name,
                updatedAt: updatedAt,
                budget: budget,
                retries: retries,
                currency: currency,
                windowDays: windowDays,
                score: score,
                discount: discount,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a global credential target in status idle.
    static func newGlobalCredentialTarget(_ code: String, name: String) -> GlobalCredentialTarget {
        return GlobalCredentialTarget(
            code: code,
            name: name,
            updatedAt: 0,
            budget: 0.0,
            retries: 0,
            currency: "",
            windowDays: 0,
            score: 0.0,
            discount: 0.0,
            diagnosisCode: "",
            status: GlobalCredentialTargetStatus.idle
        )
    }
}
