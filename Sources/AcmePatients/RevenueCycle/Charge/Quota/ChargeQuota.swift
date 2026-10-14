import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge quota is in its life cycle.
    enum ChargeQuotaStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A charge quota as the charge team keeps it.
    final class ChargeQuota {
        var code: String
        var title: String
        var region: String
        var tags: [String]
        var rate: Double
        var dosageMg: Double
        var summary: String
        var status: ChargeQuotaStatus

        init(code: String, title: String, region: String, tags: [String], rate: Double, dosageMg: Double, summary: String, status: ChargeQuotaStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.tags = tags
            self.rate = rate
            self.dosageMg = dosageMg
            self.summary = summary
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

        func canMoveTo(_ next: ChargeQuotaStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ChargeQuotaStatus.inProgress || next == ChargeQuotaStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ChargeQuotaStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ChargeQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netTotal() -> Double {
            return ((rate + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> ChargeQuota {
            return ChargeQuota(
                code: code,
                title: title,
                region: region,
                tags: tags,
                rate: rate,
                dosageMg: dosageMg,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a charge quota in status planned.
    static func newChargeQuota(_ code: String, title: String) -> ChargeQuota {
        return ChargeQuota(
            code: code,
            title: title,
            region: "",
            tags: [],
            rate: 0.0,
            dosageMg: 0.0,
            summary: "",
            status: ChargeQuotaStatus.planned
        )
    }
}
