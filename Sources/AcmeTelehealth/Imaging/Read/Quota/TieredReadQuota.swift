import AcmePlatform
import Foundation

extension Imaging {
    /// Where a tiered read quota is in its life cycle.
    enum TieredReadQuotaStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a tiered read quota and its current status.
    final class TieredReadQuota {
        var code: String
        var title: String
        var endsAt: Int
        var startsAt: Int
        var locale: String
        var margin: Double
        var channel: String
        var approved: Bool
        var score: Double
        var version: Int
        var region: String
        var status: TieredReadQuotaStatus

        init(code: String, title: String, endsAt: Int, startsAt: Int, locale: String, margin: Double, channel: String, approved: Bool, score: Double, version: Int, region: String, status: TieredReadQuotaStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.startsAt = startsAt
            self.locale = locale
            self.margin = margin
            self.channel = channel
            self.approved = approved
            self.score = score
            self.version = version
            self.region = region
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredReadQuotaStatus) -> Bool {
            switch status {
            case .draft:
                return next == TieredReadQuotaStatus.pending || next == TieredReadQuotaStatus.suspended
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: TieredReadQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered read quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("tiered read quota") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(version) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> TieredReadQuota {
            return TieredReadQuota(
                code: code,
                title: title,
                endsAt: endsAt,
                startsAt: startsAt,
                locale: locale,
                margin: margin,
                channel: channel,
                approved: approved,
                score: score,
                version: version,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a tiered read quota in status draft.
    static func newTieredReadQuota(_ code: String, title: String) -> TieredReadQuota {
        return TieredReadQuota(
            code: code,
            title: title,
            endsAt: 0,
            startsAt: 0,
            locale: "",
            margin: 0.0,
            channel: "",
            approved: false,
            score: 0.0,
            version: 0,
            region: "",
            status: TieredReadQuotaStatus.draft
        )
    }
}
