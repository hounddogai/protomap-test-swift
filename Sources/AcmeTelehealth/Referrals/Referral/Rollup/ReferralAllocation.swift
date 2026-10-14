import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral allocation is in its life cycle.
    enum ReferralAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A referral allocation. Its code is unique within a tenant.
    final class ReferralAllocation {
        var code: String
        var title: String
        var ratio: Double
        var source: String
        var endsAt: Int
        var createdAt: Int
        var locale: String
        var margin: Double
        var status: ReferralAllocationStatus

        init(code: String, title: String, ratio: Double, source: String, endsAt: Int, createdAt: Int, locale: String, margin: Double, status: ReferralAllocationStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.source = source
            self.endsAt = endsAt
            self.createdAt = createdAt
            self.locale = locale
            self.margin = margin
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

        func canMoveTo(_ next: ReferralAllocationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ReferralAllocationStatus.running || next == ReferralAllocationStatus.failed
            case .running:
                return next == ReferralAllocationStatus.failed
            case .done:
                return next == ReferralAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("referral allocation") \(code)"
        }

        func netValue() -> Double {
            return ((Double(createdAt) - Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> ReferralAllocation {
            return ReferralAllocation(
                code: code,
                title: title,
                ratio: ratio,
                source: source,
                endsAt: endsAt,
                createdAt: createdAt,
                locale: locale,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a referral allocation in status new.
    static func newReferralAllocation(_ code: String, title: String) -> ReferralAllocation {
        return ReferralAllocation(
            code: code,
            title: title,
            ratio: 0.0,
            source: "",
            endsAt: 0,
            createdAt: 0,
            locale: "",
            margin: 0.0,
            status: ReferralAllocationStatus.new
        )
    }
}
