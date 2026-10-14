import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial threshold is in its life cycle.
    enum DenialThresholdStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A denial threshold as the denial team keeps it.
    final class DenialThreshold {
        var code: String
        var title: String
        var graceDays: Int
        var visitMinutes: Int
        var quantity: Int
        var archived: Bool
        var createdAt: Int
        var externalRef: String
        var status: DenialThresholdStatus

        init(code: String, title: String, graceDays: Int, visitMinutes: Int, quantity: Int, archived: Bool, createdAt: Int, externalRef: String, status: DenialThresholdStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.visitMinutes = visitMinutes
            self.quantity = quantity
            self.archived = archived
            self.createdAt = createdAt
            self.externalRef = externalRef
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

        func canMoveTo(_ next: DenialThresholdStatus) -> Bool {
            switch status {
            case .idle:
                return next == DenialThresholdStatus.draining
            case .warming:
                return next == DenialThresholdStatus.draining
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DenialThresholdStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedExposure() -> Double {
            return ((Double(graceDays) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DenialThreshold {
            return DenialThreshold(
                code: code,
                title: title,
                graceDays: graceDays,
                visitMinutes: visitMinutes,
                quantity: quantity,
                archived: archived,
                createdAt: createdAt,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a denial threshold in status idle.
    static func newDenialThreshold(_ code: String, title: String) -> DenialThreshold {
        return DenialThreshold(
            code: code,
            title: title,
            graceDays: 0,
            visitMinutes: 0,
            quantity: 0,
            archived: false,
            createdAt: 0,
            externalRef: "",
            status: DenialThresholdStatus.idle
        )
    }
}
