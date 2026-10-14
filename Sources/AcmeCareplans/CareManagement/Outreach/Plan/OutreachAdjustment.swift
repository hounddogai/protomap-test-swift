import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach adjustment is in its life cycle.
    enum OutreachAdjustmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a outreach adjustment and its current status.
    final class OutreachAdjustment {
        var code: String
        var title: String
        var region: String
        var summary: String
        var endsAt: Int
        var amount: Double
        var refills: Int
        var createdAt: Int
        var currency: String
        var status: OutreachAdjustmentStatus

        init(code: String, title: String, region: String, summary: String, endsAt: Int, amount: Double, refills: Int, createdAt: Int, currency: String, status: OutreachAdjustmentStatus) {
            self.code = code
            self.title = title
            self.region = region
            self.summary = summary
            self.endsAt = endsAt
            self.amount = amount
            self.refills = refills
            self.createdAt = createdAt
            self.currency = currency
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

        func canMoveTo(_ next: OutreachAdjustmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == OutreachAdjustmentStatus.active
            case .active:
                switch next {
                case .suspended, .closed:
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

        func moveTo(_ next: OutreachAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func weightedVolume() -> Double {
            return ((Double(endsAt) + Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> OutreachAdjustment {
            return OutreachAdjustment(
                code: code,
                title: title,
                region: region,
                summary: summary,
                endsAt: endsAt,
                amount: amount,
                refills: refills,
                createdAt: createdAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a outreach adjustment in status draft.
    static func newOutreachAdjustment(_ code: String, title: String) -> OutreachAdjustment {
        return OutreachAdjustment(
            code: code,
            title: title,
            region: "",
            summary: "",
            endsAt: 0,
            amount: 0.0,
            refills: 0,
            createdAt: 0,
            currency: "",
            status: OutreachAdjustmentStatus.draft
        )
    }
}
