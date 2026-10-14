import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy adjustment is in its life cycle.
    enum ProxyAdjustmentStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A proxy adjustment as the proxy team keeps it.
    final class ProxyAdjustment {
        var code: String
        var label: String
        var refills: Int
        var title: String
        var cost: Double
        var discount: Double
        var specialty: String
        var description: String
        var endsAt: Int
        var contactEmail: String
        var status: ProxyAdjustmentStatus

        init(code: String, label: String, refills: Int, title: String, cost: Double, discount: Double, specialty: String, description: String, endsAt: Int, contactEmail: String, status: ProxyAdjustmentStatus) {
            self.code = code
            self.label = label
            self.refills = refills
            self.title = title
            self.cost = cost
            self.discount = discount
            self.specialty = specialty
            self.description = description
            self.endsAt = endsAt
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: ProxyAdjustmentStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ProxyAdjustmentStatus.resolved
            case .inReview:
                return next == ProxyAdjustmentStatus.resolved
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ProxyAdjustmentStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedValue() -> Double {
            return ((Double(endsAt) - cost) * 100).rounded() / 100
        }

        func copyValue() -> ProxyAdjustment {
            return ProxyAdjustment(
                code: code,
                label: label,
                refills: refills,
                title: title,
                cost: cost,
                discount: discount,
                specialty: specialty,
                description: description,
                endsAt: endsAt,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a proxy adjustment in status open.
    static func newProxyAdjustment(_ code: String, label: String) -> ProxyAdjustment {
        return ProxyAdjustment(
            code: code,
            label: label,
            refills: 0,
            title: "",
            cost: 0.0,
            discount: 0.0,
            specialty: "",
            description: "",
            endsAt: 0,
            contactEmail: "",
            status: ProxyAdjustmentStatus.`open`
        )
    }
}
