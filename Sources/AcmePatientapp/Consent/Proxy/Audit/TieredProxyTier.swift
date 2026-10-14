import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered proxy tier is in its life cycle.
    enum TieredProxyTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A tiered proxy tier as the proxy team keeps it.
    final class TieredProxyTier {
        var code: String
        var title: String
        var clinicianID: String
        var notes: String
        var approved: Bool
        var windowDays: Int
        var priority: Int
        var maximum: Double
        var limit: Int
        var status: TieredProxyTierStatus

        init(code: String, title: String, clinicianID: String, notes: String, approved: Bool, windowDays: Int, priority: Int, maximum: Double, limit: Int, status: TieredProxyTierStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.notes = notes
            self.approved = approved
            self.windowDays = windowDays
            self.priority = priority
            self.maximum = maximum
            self.limit = limit
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

        func canMoveTo(_ next: TieredProxyTierStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == TieredProxyTierStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: TieredProxyTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered proxy tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered proxy tier") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(priority) * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> TieredProxyTier {
            return TieredProxyTier(
                code: code,
                title: title,
                clinicianID: clinicianID,
                notes: notes,
                approved: approved,
                windowDays: windowDays,
                priority: priority,
                maximum: maximum,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered proxy tier in status new.
    static func newTieredProxyTier(_ code: String, title: String) -> TieredProxyTier {
        return TieredProxyTier(
            code: code,
            title: title,
            clinicianID: "",
            notes: "",
            approved: false,
            windowDays: 0,
            priority: 0,
            maximum: 0.0,
            limit: 0,
            status: TieredProxyTierStatus.new
        )
    }
}
