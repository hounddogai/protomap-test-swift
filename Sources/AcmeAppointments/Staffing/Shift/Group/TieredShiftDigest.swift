import AcmePlatform
import Foundation

extension Staffing {
    /// Where a tiered shift digest is in its life cycle.
    enum TieredShiftDigestStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a tiered shift digest and its current status.
    final class TieredShiftDigest {
        var code: String
        var title: String
        var startsAt: Int
        var quantity: Int
        var category: String
        var contactEmail: String
        var unit: String
        var locale: String
        var priority: Int
        var diagnosisCode: String
        var ratio: Double
        var status: TieredShiftDigestStatus

        init(code: String, title: String, startsAt: Int, quantity: Int, category: String, contactEmail: String, unit: String, locale: String, priority: Int, diagnosisCode: String, ratio: Double, status: TieredShiftDigestStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.quantity = quantity
            self.category = category
            self.contactEmail = contactEmail
            self.unit = unit
            self.locale = locale
            self.priority = priority
            self.diagnosisCode = diagnosisCode
            self.ratio = ratio
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: TieredShiftDigestStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == TieredShiftDigestStatus.draining
            case .draining:
                return next == TieredShiftDigestStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredShiftDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered shift digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedExposure() -> Double {
            return (Double(quantity) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> TieredShiftDigest {
            return TieredShiftDigest(
                code: code,
                title: title,
                startsAt: startsAt,
                quantity: quantity,
                category: category,
                contactEmail: contactEmail,
                unit: unit,
                locale: locale,
                priority: priority,
                diagnosisCode: diagnosisCode,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a tiered shift digest in status idle.
    static func newTieredShiftDigest(_ code: String, title: String) -> TieredShiftDigest {
        return TieredShiftDigest(
            code: code,
            title: title,
            startsAt: 0,
            quantity: 0,
            category: "",
            contactEmail: "",
            unit: "",
            locale: "",
            priority: 0,
            diagnosisCode: "",
            ratio: 0.0,
            status: TieredShiftDigestStatus.idle
        )
    }
}
