import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default follow up variance is in its life cycle.
    enum DefaultFollowUpVarianceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One default follow up variance, with what the planners need to act on it.
    final class DefaultFollowUpVariance {
        var code: String
        var label: String
        var category: String
        var quantity: Int
        var version: Int
        var dosageMg: Double
        var channel: String
        var approved: Bool
        var unit: String
        var maximum: Double
        var contactEmail: String
        var status: DefaultFollowUpVarianceStatus

        init(code: String, label: String, category: String, quantity: Int, version: Int, dosageMg: Double, channel: String, approved: Bool, unit: String, maximum: Double, contactEmail: String, status: DefaultFollowUpVarianceStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.quantity = quantity
            self.version = version
            self.dosageMg = dosageMg
            self.channel = channel
            self.approved = approved
            self.unit = unit
            self.maximum = maximum
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: DefaultFollowUpVarianceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == DefaultFollowUpVarianceStatus.cancelled
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

        func moveTo(_ next: DefaultFollowUpVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default follow up variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("default follow up variance") \(code)"
        }

        func weightedExposure() -> Double {
            return ((dosageMg - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultFollowUpVariance {
            return DefaultFollowUpVariance(
                code: code,
                label: label,
                category: category,
                quantity: quantity,
                version: version,
                dosageMg: dosageMg,
                channel: channel,
                approved: approved,
                unit: unit,
                maximum: maximum,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a default follow up variance in status planned.
    static func newDefaultFollowUpVariance(_ code: String, label: String) -> DefaultFollowUpVariance {
        return DefaultFollowUpVariance(
            code: code,
            label: label,
            category: "",
            quantity: 0,
            version: 0,
            dosageMg: 0.0,
            channel: "",
            approved: false,
            unit: "",
            maximum: 0.0,
            contactEmail: "",
            status: DefaultFollowUpVarianceStatus.planned
        )
    }
}
