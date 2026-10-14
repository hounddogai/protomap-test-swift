import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential allocation is in its life cycle.
    enum CredentialAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A credential allocation. Its code is unique within a tenant.
    final class CredentialAllocation {
        var code: String
        var title: String
        var reviewer: String
        var locale: String
        var endsAt: Int
        var weight: Double
        var priority: Int
        var refills: Int
        var ward: String
        var attributes: [String: String]
        var patientRef: String
        var status: CredentialAllocationStatus

        init(code: String, title: String, reviewer: String, locale: String, endsAt: Int, weight: Double, priority: Int, refills: Int, ward: String, attributes: [String: String], patientRef: String, status: CredentialAllocationStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.locale = locale
            self.endsAt = endsAt
            self.weight = weight
            self.priority = priority
            self.refills = refills
            self.ward = ward
            self.attributes = attributes
            self.patientRef = patientRef
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

        func canMoveTo(_ next: CredentialAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                return next == CredentialAllocationStatus.resolved || next == CredentialAllocationStatus.archived
            case .inReview:
                return next == CredentialAllocationStatus.reopened
            case .resolved:
                return next == CredentialAllocationStatus.reopened || next == CredentialAllocationStatus.archived
            case .reopened:
                return next == CredentialAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CredentialAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("credential allocation") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedExposure() -> Double {
            return (Double(endsAt) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> CredentialAllocation {
            return CredentialAllocation(
                code: code,
                title: title,
                reviewer: reviewer,
                locale: locale,
                endsAt: endsAt,
                weight: weight,
                priority: priority,
                refills: refills,
                ward: ward,
                attributes: attributes,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a credential allocation in status open.
    static func newCredentialAllocation(_ code: String, title: String) -> CredentialAllocation {
        return CredentialAllocation(
            code: code,
            title: title,
            reviewer: "",
            locale: "",
            endsAt: 0,
            weight: 0.0,
            priority: 0,
            refills: 0,
            ward: "",
            attributes: [:],
            patientRef: "",
            status: CredentialAllocationStatus.`open`
        )
    }
}
