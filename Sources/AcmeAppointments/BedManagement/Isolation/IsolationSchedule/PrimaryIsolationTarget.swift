import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a primary isolation target is in its life cycle.
    enum PrimaryIsolationTargetStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One primary isolation target, with what the planners need to act on it.
    final class PrimaryIsolationTarget {
        var code: String
        var name: String
        var specialty: String
        var contactEmail: String
        var amount: Double
        var updatedAt: Int
        var approved: Bool
        var status: PrimaryIsolationTargetStatus

        init(code: String, name: String, specialty: String, contactEmail: String, amount: Double, updatedAt: Int, approved: Bool, status: PrimaryIsolationTargetStatus) {
            self.code = code
            self.name = name
            self.specialty = specialty
            self.contactEmail = contactEmail
            self.amount = amount
            self.updatedAt = updatedAt
            self.approved = approved
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

        func canMoveTo(_ next: PrimaryIsolationTargetStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == PrimaryIsolationTargetStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryIsolationTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary isolation target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedTotal() -> Double {
            return (Double(updatedAt) * amount * 100).rounded() / 100
        }

        func copyValue() -> PrimaryIsolationTarget {
            return PrimaryIsolationTarget(
                code: code,
                name: name,
                specialty: specialty,
                contactEmail: contactEmail,
                amount: amount,
                updatedAt: updatedAt,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a primary isolation target in status idle.
    static func newPrimaryIsolationTarget(_ code: String, name: String) -> PrimaryIsolationTarget {
        return PrimaryIsolationTarget(
            code: code,
            name: name,
            specialty: "",
            contactEmail: "",
            amount: 0.0,
            updatedAt: 0,
            approved: false,
            status: PrimaryIsolationTargetStatus.idle
        )
    }
}
