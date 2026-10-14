import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge target is in its life cycle.
    enum ChargeTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A charge target. Its code is unique within a tenant.
    final class ChargeTarget {
        var code: String
        var title: String
        var ward: String
        var maximum: Double
        var active: Bool
        var payer: String
        var startsAt: Int
        var category: String
        var specialty: String
        var status: ChargeTargetStatus

        init(code: String, title: String, ward: String, maximum: Double, active: Bool, payer: String, startsAt: Int, category: String, specialty: String, status: ChargeTargetStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.maximum = maximum
            self.active = active
            self.payer = payer
            self.startsAt = startsAt
            self.category = category
            self.specialty = specialty
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ChargeTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ChargeTargetStatus.inReview || next == ChargeTargetStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ChargeTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("charge target") \(code)"
        }

        func projectedVolume() -> Double {
            return (maximum * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ChargeTarget {
            return ChargeTarget(
                code: code,
                title: title,
                ward: ward,
                maximum: maximum,
                active: active,
                payer: payer,
                startsAt: startsAt,
                category: category,
                specialty: specialty,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a charge target in status open.
    static func newChargeTarget(_ code: String, title: String) -> ChargeTarget {
        return ChargeTarget(
            code: code,
            title: title,
            ward: "",
            maximum: 0.0,
            active: false,
            payer: "",
            startsAt: 0,
            category: "",
            specialty: "",
            status: ChargeTargetStatus.`open`
        )
    }
}
