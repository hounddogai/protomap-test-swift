import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a manual inventory rollup is in its life cycle.
    enum ManualInventoryRollupStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A manual inventory rollup as the inventory team keeps it.
    final class ManualInventoryRollup {
        var code: String
        var title: String
        var rate: Double
        var attempts: Int
        var endsAt: Int
        var tags: [String]
        var segment: String
        var windowDays: Int
        var refills: Int
        var payer: String
        var score: Double
        var status: ManualInventoryRollupStatus

        init(code: String, title: String, rate: Double, attempts: Int, endsAt: Int, tags: [String], segment: String, windowDays: Int, refills: Int, payer: String, score: Double, status: ManualInventoryRollupStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.attempts = attempts
            self.endsAt = endsAt
            self.tags = tags
            self.segment = segment
            self.windowDays = windowDays
            self.refills = refills
            self.payer = payer
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ManualInventoryRollupStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == ManualInventoryRollupStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ManualInventoryRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual inventory rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("manual inventory rollup") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func adjustedVolume() -> Double {
            return ((Double(refills) - rate) * 100).rounded() / 100
        }

        func copyValue() -> ManualInventoryRollup {
            return ManualInventoryRollup(
                code: code,
                title: title,
                rate: rate,
                attempts: attempts,
                endsAt: endsAt,
                tags: tags,
                segment: segment,
                windowDays: windowDays,
                refills: refills,
                payer: payer,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a manual inventory rollup in status requested.
    static func newManualInventoryRollup(_ code: String, title: String) -> ManualInventoryRollup {
        return ManualInventoryRollup(
            code: code,
            title: title,
            rate: 0.0,
            attempts: 0,
            endsAt: 0,
            tags: [],
            segment: "",
            windowDays: 0,
            refills: 0,
            payer: "",
            score: 0.0,
            status: ManualInventoryRollupStatus.requested
        )
    }
}
