import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization cycle is in its life cycle.
    enum AuthorizationCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One authorization cycle, with what the planners need to act on it.
    final class AuthorizationCycle {
        var code: String
        var name: String
        var allergy: String
        var threshold: Double
        var externalRef: String
        var acuity: Int
        var windowDays: Int
        var batchSize: Int
        var copay: Double
        var revision: Int
        var reviewer: String
        var status: AuthorizationCycleStatus

        init(code: String, name: String, allergy: String, threshold: Double, externalRef: String, acuity: Int, windowDays: Int, batchSize: Int, copay: Double, revision: Int, reviewer: String, status: AuthorizationCycleStatus) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.threshold = threshold
            self.externalRef = externalRef
            self.acuity = acuity
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.copay = copay
            self.revision = revision
            self.reviewer = reviewer
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

        func canMoveTo(_ next: AuthorizationCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == AuthorizationCycleStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AuthorizationCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func adjustedTotal() -> Double {
            return ((copay + threshold) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationCycle {
            return AuthorizationCycle(
                code: code,
                name: name,
                allergy: allergy,
                threshold: threshold,
                externalRef: externalRef,
                acuity: acuity,
                windowDays: windowDays,
                batchSize: batchSize,
                copay: copay,
                revision: revision,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a authorization cycle in status created.
    static func newAuthorizationCycle(_ code: String, name: String) -> AuthorizationCycle {
        return AuthorizationCycle(
            code: code,
            name: name,
            allergy: "",
            threshold: 0.0,
            externalRef: "",
            acuity: 0,
            windowDays: 0,
            batchSize: 0,
            copay: 0.0,
            revision: 0,
            reviewer: "",
            status: AuthorizationCycleStatus.created
        )
    }
}
