import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense claim is in its life cycle.
    enum DispenseClaimStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One dispense claim, with what the planners need to act on it.
    final class DispenseClaim {
        var code: String
        var title: String
        var updatedAt: Int
        var tags: [String]
        var retries: Int
        var windowDays: Int
        var status: DispenseClaimStatus

        init(code: String, title: String, updatedAt: Int, tags: [String], retries: Int, windowDays: Int, status: DispenseClaimStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.tags = tags
            self.retries = retries
            self.windowDays = windowDays
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

        func canMoveTo(_ next: DispenseClaimStatus) -> Bool {
            switch status {
            case .idle:
                return next == DispenseClaimStatus.draining
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == DispenseClaimStatus.draining || next == DispenseClaimStatus.stopped
            case .draining:
                return next == DispenseClaimStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DispenseClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("dispense claim") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return (Double(retries) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> DispenseClaim {
            return DispenseClaim(
                code: code,
                title: title,
                updatedAt: updatedAt,
                tags: tags,
                retries: retries,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense claim in status idle.
    static func newDispenseClaim(_ code: String, title: String) -> DispenseClaim {
        return DispenseClaim(
            code: code,
            title: title,
            updatedAt: 0,
            tags: [],
            retries: 0,
            windowDays: 0,
            status: DispenseClaimStatus.idle
        )
    }
}
