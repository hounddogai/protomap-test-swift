import AcmePlatform
import Foundation

extension Consent {
    /// Where a lenient revocation bundle is in its life cycle.
    enum LenientRevocationBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A lenient revocation bundle. Its code is unique within a tenant.
    final class LenientRevocationBundle {
        var code: String
        var name: String
        var pinned: Bool
        var contactEmail: String
        var allergy: String
        var region: String
        var refills: Int
        var status: LenientRevocationBundleStatus

        init(code: String, name: String, pinned: Bool, contactEmail: String, allergy: String, region: String, refills: Int, status: LenientRevocationBundleStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.contactEmail = contactEmail
            self.allergy = allergy
            self.region = region
            self.refills = refills
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

        func canMoveTo(_ next: LenientRevocationBundleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LenientRevocationBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientRevocationBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient revocation bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func measuredValue() -> Double {
            return Double(refills)
        }

        func copyValue() -> LenientRevocationBundle {
            return LenientRevocationBundle(
                code: code,
                name: name,
                pinned: pinned,
                contactEmail: contactEmail,
                allergy: allergy,
                region: region,
                refills: refills,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a lenient revocation bundle in status open.
    static func newLenientRevocationBundle(_ code: String, name: String) -> LenientRevocationBundle {
        return LenientRevocationBundle(
            code: code,
            name: name,
            pinned: false,
            contactEmail: "",
            allergy: "",
            region: "",
            refills: 0,
            status: LenientRevocationBundleStatus.`open`
        )
    }
}
