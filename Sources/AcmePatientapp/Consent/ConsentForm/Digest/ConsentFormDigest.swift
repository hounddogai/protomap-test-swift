import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form digest is in its life cycle.
    enum ConsentFormDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A consent form digest. Its code is unique within a tenant.
    final class ConsentFormDigest {
        var code: String
        var name: String
        var category: String
        var pinned: Bool
        var clinicianID: String
        var quantity: Int
        var status: ConsentFormDigestStatus

        init(code: String, name: String, category: String, pinned: Bool, clinicianID: String, quantity: Int, status: ConsentFormDigestStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ConsentFormDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ConsentFormDigestStatus.rejected
            case .approved:
                return next == ConsentFormDigestStatus.rejected || next == ConsentFormDigestStatus.withdrawn
            case .rejected:
                return next == ConsentFormDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ConsentFormDigest {
            return ConsentFormDigest(
                code: code,
                name: name,
                category: category,
                pinned: pinned,
                clinicianID: clinicianID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a consent form digest in status proposed.
    static func newConsentFormDigest(_ code: String, name: String) -> ConsentFormDigest {
        return ConsentFormDigest(
            code: code,
            name: name,
            category: "",
            pinned: false,
            clinicianID: "",
            quantity: 0,
            status: ConsentFormDigestStatus.proposed
        )
    }
}
