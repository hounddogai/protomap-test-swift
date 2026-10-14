import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a tiered charge variance is in its life cycle.
    enum TieredChargeVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A tiered charge variance as the charge team keeps it.
    final class TieredChargeVariance {
        var code: String
        var title: String
        var tags: [String]
        var startsAt: Int
        var attempts: Int
        var clinicianID: String
        var status: TieredChargeVarianceStatus

        init(code: String, title: String, tags: [String], startsAt: Int, attempts: Int, clinicianID: String, status: TieredChargeVarianceStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.startsAt = startsAt
            self.attempts = attempts
            self.clinicianID = clinicianID
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredChargeVarianceStatus) -> Bool {
            switch status {
            case .planned:
                return next == TieredChargeVarianceStatus.scheduled
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == TieredChargeVarianceStatus.completed || next == TieredChargeVarianceStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: TieredChargeVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered charge variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("tiered charge variance") \(code)"
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
            return ((Double(startsAt) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> TieredChargeVariance {
            return TieredChargeVariance(
                code: code,
                title: title,
                tags: tags,
                startsAt: startsAt,
                attempts: attempts,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered charge variance in status planned.
    static func newTieredChargeVariance(_ code: String, title: String) -> TieredChargeVariance {
        return TieredChargeVariance(
            code: code,
            title: title,
            tags: [],
            startsAt: 0,
            attempts: 0,
            clinicianID: "",
            status: TieredChargeVarianceStatus.planned
        )
    }
}
