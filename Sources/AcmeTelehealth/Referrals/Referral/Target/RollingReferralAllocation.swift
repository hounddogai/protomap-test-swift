import AcmePlatform
import Foundation

extension Referrals {
    /// Where a rolling referral allocation is in its life cycle.
    enum RollingReferralAllocationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling referral allocation and its current status.
    final class RollingReferralAllocation {
        var code: String
        var title: String
        var country: String
        var facility: String
        var timezone: String
        var checksum: String
        var discount: Double
        var ratio: Double
        var description: String
        var startsAt: Int
        var status: RollingReferralAllocationStatus

        init(code: String, title: String, country: String, facility: String, timezone: String, checksum: String, discount: Double, ratio: Double, description: String, startsAt: Int, status: RollingReferralAllocationStatus) {
            self.code = code
            self.title = title
            self.country = country
            self.facility = facility
            self.timezone = timezone
            self.checksum = checksum
            self.discount = discount
            self.ratio = ratio
            self.description = description
            self.startsAt = startsAt
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

        func canMoveTo(_ next: RollingReferralAllocationStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingReferralAllocationStatus.running || next == RollingReferralAllocationStatus.done
            case .queued:
                switch next {
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == RollingReferralAllocationStatus.done || next == RollingReferralAllocationStatus.failed
            case .done:
                return next == RollingReferralAllocationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingReferralAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling referral allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netTotal() -> Double {
            return ((ratio - discount) * 100).rounded() / 100
        }

        func copyValue() -> RollingReferralAllocation {
            return RollingReferralAllocation(
                code: code,
                title: title,
                country: country,
                facility: facility,
                timezone: timezone,
                checksum: checksum,
                discount: discount,
                ratio: ratio,
                description: description,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a rolling referral allocation in status new.
    static func newRollingReferralAllocation(_ code: String, title: String) -> RollingReferralAllocation {
        return RollingReferralAllocation(
            code: code,
            title: title,
            country: "",
            facility: "",
            timezone: "",
            checksum: "",
            discount: 0.0,
            ratio: 0.0,
            description: "",
            startsAt: 0,
            status: RollingReferralAllocationStatus.new
        )
    }
}
