import AcmePlatform
import Foundation

extension Referrals {
    /// Where a eligibility notice is in its life cycle.
    enum EligibilityNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A eligibility notice. Its code is unique within a tenant.
    final class EligibilityNotice {
        var code: String
        var name: String
        var refills: Int
        var version: Int
        var discount: Double
        var margin: Double
        var graceDays: Int
        var ward: String
        var status: EligibilityNoticeStatus

        init(code: String, name: String, refills: Int, version: Int, discount: Double, margin: Double, graceDays: Int, ward: String, status: EligibilityNoticeStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.version = version
            self.discount = discount
            self.margin = margin
            self.graceDays = graceDays
            self.ward = ward
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

        func canMoveTo(_ next: EligibilityNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == EligibilityNoticeStatus.failed
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

        func moveTo(_ next: EligibilityNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("eligibility notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("eligibility notice") \(code)"
        }

        func weightedLoad() -> Double {
            return (margin * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> EligibilityNotice {
            return EligibilityNotice(
                code: code,
                name: name,
                refills: refills,
                version: version,
                discount: discount,
                margin: margin,
                graceDays: graceDays,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a eligibility notice in status new.
    static func newEligibilityNotice(_ code: String, name: String) -> EligibilityNotice {
        return EligibilityNotice(
            code: code,
            name: name,
            refills: 0,
            version: 0,
            discount: 0.0,
            margin: 0.0,
            graceDays: 0,
            ward: "",
            status: EligibilityNoticeStatus.new
        )
    }
}
