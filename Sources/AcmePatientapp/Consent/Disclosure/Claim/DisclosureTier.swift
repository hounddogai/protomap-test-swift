import AcmePlatform
import Foundation

extension Consent {
    /// Where a disclosure tier is in its life cycle.
    enum DisclosureTierStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One disclosure tier, with what the planners need to act on it.
    final class DisclosureTier {
        var code: String
        var title: String
        var startsAt: Int
        var cost: Double
        var endsAt: Int
        var summary: String
        var region: String
        var active: Bool
        var visitMinutes: Int
        var graceDays: Int
        var batchSize: Int
        var status: DisclosureTierStatus

        init(code: String, title: String, startsAt: Int, cost: Double, endsAt: Int, summary: String, region: String, active: Bool, visitMinutes: Int, graceDays: Int, batchSize: Int, status: DisclosureTierStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.cost = cost
            self.endsAt = endsAt
            self.summary = summary
            self.region = region
            self.active = active
            self.visitMinutes = visitMinutes
            self.graceDays = graceDays
            self.batchSize = batchSize
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

        func canMoveTo(_ next: DisclosureTierStatus) -> Bool {
            switch status {
            case .new:
                return next == DisclosureTierStatus.running || next == DisclosureTierStatus.failed
            case .queued:
                return next == DisclosureTierStatus.done
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

        func moveTo(_ next: DisclosureTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("disclosure tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("disclosure tier") \(code)"
        }

        func effectiveExposure() -> Double {
            return ((Double(startsAt) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> DisclosureTier {
            return DisclosureTier(
                code: code,
                title: title,
                startsAt: startsAt,
                cost: cost,
                endsAt: endsAt,
                summary: summary,
                region: region,
                active: active,
                visitMinutes: visitMinutes,
                graceDays: graceDays,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a disclosure tier in status new.
    static func newDisclosureTier(_ code: String, title: String) -> DisclosureTier {
        return DisclosureTier(
            code: code,
            title: title,
            startsAt: 0,
            cost: 0.0,
            endsAt: 0,
            summary: "",
            region: "",
            active: false,
            visitMinutes: 0,
            graceDays: 0,
            batchSize: 0,
            status: DisclosureTierStatus.new
        )
    }
}
