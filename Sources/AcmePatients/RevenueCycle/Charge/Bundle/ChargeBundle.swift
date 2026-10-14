import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a charge bundle is in its life cycle.
    enum ChargeBundleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A charge bundle as the charge team keeps it.
    final class ChargeBundle {
        var code: String
        var title: String
        var encounterID: String
        var discount: Double
        var margin: Double
        var rate: Double
        var category: String
        var contactEmail: String
        var version: Int
        var status: ChargeBundleStatus

        init(code: String, title: String, encounterID: String, discount: Double, margin: Double, rate: Double, category: String, contactEmail: String, version: Int, status: ChargeBundleStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.discount = discount
            self.margin = margin
            self.rate = rate
            self.category = category
            self.contactEmail = contactEmail
            self.version = version
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

        func canMoveTo(_ next: ChargeBundleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ChargeBundleStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ChargeBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("charge bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("charge bundle") \(code)"
        }

        func weightedExposure() -> Double {
            return ((margin + rate) * 100).rounded() / 100
        }

        func copyValue() -> ChargeBundle {
            return ChargeBundle(
                code: code,
                title: title,
                encounterID: encounterID,
                discount: discount,
                margin: margin,
                rate: rate,
                category: category,
                contactEmail: contactEmail,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a charge bundle in status idle.
    static func newChargeBundle(_ code: String, title: String) -> ChargeBundle {
        return ChargeBundle(
            code: code,
            title: title,
            encounterID: "",
            discount: 0.0,
            margin: 0.0,
            rate: 0.0,
            category: "",
            contactEmail: "",
            version: 0,
            status: ChargeBundleStatus.idle
        )
    }
}
