import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a manual denial profile is in its life cycle.
    enum ManualDenialProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a manual denial profile and its current status.
    final class ManualDenialProfile {
        var code: String
        var title: String
        var externalRef: String
        var allergy: String
        var label: String
        var limit: Int
        var revision: Int
        var phone: String
        var status: ManualDenialProfileStatus

        init(code: String, title: String, externalRef: String, allergy: String, label: String, limit: Int, revision: Int, phone: String, status: ManualDenialProfileStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.allergy = allergy
            self.label = label
            self.limit = limit
            self.revision = revision
            self.phone = phone
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

        func canMoveTo(_ next: ManualDenialProfileStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
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

        func moveTo(_ next: ManualDenialProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual denial profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("manual denial profile") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(revision) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> ManualDenialProfile {
            return ManualDenialProfile(
                code: code,
                title: title,
                externalRef: externalRef,
                allergy: allergy,
                label: label,
                limit: limit,
                revision: revision,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a manual denial profile in status open.
    static func newManualDenialProfile(_ code: String, title: String) -> ManualDenialProfile {
        return ManualDenialProfile(
            code: code,
            title: title,
            externalRef: "",
            allergy: "",
            label: "",
            limit: 0,
            revision: 0,
            phone: "",
            status: ManualDenialProfileStatus.`open`
        )
    }
}
