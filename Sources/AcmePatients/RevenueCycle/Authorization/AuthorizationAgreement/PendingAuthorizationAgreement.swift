import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a pending authorization agreement is in its life cycle.
    enum PendingAuthorizationAgreementStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A pending authorization agreement as the authorization team keeps it.
    final class PendingAuthorizationAgreement {
        var code: String
        var title: String
        var version: Int
        var refills: Int
        var approved: Bool
        var unit: String
        var tags: [String]
        var updatedAt: Int
        var ward: String
        var pinned: Bool
        var status: PendingAuthorizationAgreementStatus

        init(code: String, title: String, version: Int, refills: Int, approved: Bool, unit: String, tags: [String], updatedAt: Int, ward: String, pinned: Bool, status: PendingAuthorizationAgreementStatus) {
            self.code = code
            self.title = title
            self.version = version
            self.refills = refills
            self.approved = approved
            self.unit = unit
            self.tags = tags
            self.updatedAt = updatedAt
            self.ward = ward
            self.pinned = pinned
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

        func canMoveTo(_ next: PendingAuthorizationAgreementStatus) -> Bool {
            switch status {
            case .`open`:
                return next == PendingAuthorizationAgreementStatus.archived
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: PendingAuthorizationAgreementStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending authorization agreement \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("pending authorization agreement") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return ((Double(version) - Double(refills)) * 100).rounded() / 100
        }

        func copyValue() -> PendingAuthorizationAgreement {
            return PendingAuthorizationAgreement(
                code: code,
                title: title,
                version: version,
                refills: refills,
                approved: approved,
                unit: unit,
                tags: tags,
                updatedAt: updatedAt,
                ward: ward,
                pinned: pinned,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a pending authorization agreement in status open.
    static func newPendingAuthorizationAgreement(_ code: String, title: String) -> PendingAuthorizationAgreement {
        return PendingAuthorizationAgreement(
            code: code,
            title: title,
            version: 0,
            refills: 0,
            approved: false,
            unit: "",
            tags: [],
            updatedAt: 0,
            ward: "",
            pinned: false,
            status: PendingAuthorizationAgreementStatus.`open`
        )
    }
}
