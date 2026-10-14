import AcmePlatform
import Foundation

extension Imaging {
    /// Where a primary study digest is in its life cycle.
    enum PrimaryStudyDigestStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary study digest. Its code is unique within a tenant.
    final class PrimaryStudyDigest {
        var code: String
        var name: String
        var ward: String
        var budget: Double
        var active: Bool
        var country: String
        var endsAt: Int
        var segment: String
        var status: PrimaryStudyDigestStatus

        init(code: String, name: String, ward: String, budget: Double, active: Bool, country: String, endsAt: Int, segment: String, status: PrimaryStudyDigestStatus) {
            self.code = code
            self.name = name
            self.ward = ward
            self.budget = budget
            self.active = active
            self.country = country
            self.endsAt = endsAt
            self.segment = segment
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

        func canMoveTo(_ next: PrimaryStudyDigestStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryStudyDigestStatus.rejected
            case .approved:
                return next == PrimaryStudyDigestStatus.withdrawn
            case .rejected:
                return next == PrimaryStudyDigestStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryStudyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary study digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedLoad() -> Double {
            return (budget * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryStudyDigest {
            return PrimaryStudyDigest(
                code: code,
                name: name,
                ward: ward,
                budget: budget,
                active: active,
                country: country,
                endsAt: endsAt,
                segment: segment,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a primary study digest in status proposed.
    static func newPrimaryStudyDigest(_ code: String, name: String) -> PrimaryStudyDigest {
        return PrimaryStudyDigest(
            code: code,
            name: name,
            ward: "",
            budget: 0.0,
            active: false,
            country: "",
            endsAt: 0,
            segment: "",
            status: PrimaryStudyDigestStatus.proposed
        )
    }
}
