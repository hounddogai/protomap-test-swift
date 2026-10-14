import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool tier is in its life cycle.
    enum FloatPoolTierStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a float pool tier and its current status.
    final class FloatPoolTier {
        var code: String
        var title: String
        var locale: String
        var weight: Double
        var label: String
        var visitMinutes: Int
        var phone: String
        var retries: Int
        var visible: Bool
        var budget: Double
        var status: FloatPoolTierStatus

        init(code: String, title: String, locale: String, weight: Double, label: String, visitMinutes: Int, phone: String, retries: Int, visible: Bool, budget: Double, status: FloatPoolTierStatus) {
            self.code = code
            self.title = title
            self.locale = locale
            self.weight = weight
            self.label = label
            self.visitMinutes = visitMinutes
            self.phone = phone
            self.retries = retries
            self.visible = visible
            self.budget = budget
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

        func canMoveTo(_ next: FloatPoolTierStatus) -> Bool {
            switch status {
            case .planned:
                return next == FloatPoolTierStatus.inProgress
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: FloatPoolTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("float pool tier") \(code)"
        }

        func netExposure() -> Double {
            return ((budget - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolTier {
            return FloatPoolTier(
                code: code,
                title: title,
                locale: locale,
                weight: weight,
                label: label,
                visitMinutes: visitMinutes,
                phone: phone,
                retries: retries,
                visible: visible,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a float pool tier in status planned.
    static func newFloatPoolTier(_ code: String, title: String) -> FloatPoolTier {
        return FloatPoolTier(
            code: code,
            title: title,
            locale: "",
            weight: 0.0,
            label: "",
            visitMinutes: 0,
            phone: "",
            retries: 0,
            visible: false,
            budget: 0.0,
            status: FloatPoolTierStatus.planned
        )
    }
}
