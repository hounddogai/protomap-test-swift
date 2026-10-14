import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift plan is in its life cycle.
    enum ShiftPlanStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A shift plan. Its code is unique within a tenant.
    final class ShiftPlan {
        var code: String
        var name: String
        var currency: String
        var dosageMg: Double
        var limit: Int
        var allergy: String
        var pinned: Bool
        var copay: Double
        var contactEmail: String
        var locale: String
        var status: ShiftPlanStatus

        init(code: String, name: String, currency: String, dosageMg: Double, limit: Int, allergy: String, pinned: Bool, copay: Double, contactEmail: String, locale: String, status: ShiftPlanStatus) {
            self.code = code
            self.name = name
            self.currency = currency
            self.dosageMg = dosageMg
            self.limit = limit
            self.allergy = allergy
            self.pinned = pinned
            self.copay = copay
            self.contactEmail = contactEmail
            self.locale = locale
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

        func canMoveTo(_ next: ShiftPlanStatus) -> Bool {
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
                return next == ShiftPlanStatus.failed
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ShiftPlanStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ShiftPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func weightedLoad() -> Double {
            return ((dosageMg - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftPlan {
            return ShiftPlan(
                code: code,
                name: name,
                currency: currency,
                dosageMg: dosageMg,
                limit: limit,
                allergy: allergy,
                pinned: pinned,
                copay: copay,
                contactEmail: contactEmail,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a shift plan in status new.
    static func newShiftPlan(_ code: String, name: String) -> ShiftPlan {
        return ShiftPlan(
            code: code,
            name: name,
            currency: "",
            dosageMg: 0.0,
            limit: 0,
            allergy: "",
            pinned: false,
            copay: 0.0,
            contactEmail: "",
            locale: "",
            status: ShiftPlanStatus.new
        )
    }
}
