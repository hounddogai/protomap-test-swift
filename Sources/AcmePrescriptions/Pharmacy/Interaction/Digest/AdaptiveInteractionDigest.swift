import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a adaptive interaction digest is in its life cycle.
    enum AdaptiveInteractionDigestStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A adaptive interaction digest. Its code is unique within a tenant.
    final class AdaptiveInteractionDigest {
        var code: String
        var label: String
        var windowDays: Int
        var limit: Int
        var floorValue: Double
        var discount: Double
        var startsAt: Int
        var allergy: String
        var locale: String
        var status: AdaptiveInteractionDigestStatus

        init(code: String, label: String, windowDays: Int, limit: Int, floorValue: Double, discount: Double, startsAt: Int, allergy: String, locale: String, status: AdaptiveInteractionDigestStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.limit = limit
            self.floorValue = floorValue
            self.discount = discount
            self.startsAt = startsAt
            self.allergy = allergy
            self.locale = locale
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

        func canMoveTo(_ next: AdaptiveInteractionDigestStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == AdaptiveInteractionDigestStatus.completed
            case .completed:
                return next == AdaptiveInteractionDigestStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveInteractionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive interaction digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func effectiveTotal() -> Double {
            return (Double(windowDays) * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveInteractionDigest {
            return AdaptiveInteractionDigest(
                code: code,
                label: label,
                windowDays: windowDays,
                limit: limit,
                floorValue: floorValue,
                discount: discount,
                startsAt: startsAt,
                allergy: allergy,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a adaptive interaction digest in status planned.
    static func newAdaptiveInteractionDigest(_ code: String, label: String) -> AdaptiveInteractionDigest {
        return AdaptiveInteractionDigest(
            code: code,
            label: label,
            windowDays: 0,
            limit: 0,
            floorValue: 0.0,
            discount: 0.0,
            startsAt: 0,
            allergy: "",
            locale: "",
            status: AdaptiveInteractionDigestStatus.planned
        )
    }
}
