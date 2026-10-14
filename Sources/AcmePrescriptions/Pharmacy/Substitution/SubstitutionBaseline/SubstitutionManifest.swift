import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a substitution manifest is in its life cycle.
    enum SubstitutionManifestStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One substitution manifest, with what the planners need to act on it.
    final class SubstitutionManifest {
        var code: String
        var title: String
        var discount: Double
        var label: String
        var attributes: [String: String]
        var updatedAt: Int
        var amount: Double
        var ownerID: String
        var startsAt: Int
        var status: SubstitutionManifestStatus

        init(code: String, title: String, discount: Double, label: String, attributes: [String: String], updatedAt: Int, amount: Double, ownerID: String, startsAt: Int, status: SubstitutionManifestStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.label = label
            self.attributes = attributes
            self.updatedAt = updatedAt
            self.amount = amount
            self.ownerID = ownerID
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SubstitutionManifestStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SubstitutionManifestStatus.suspended || next == SubstitutionManifestStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: SubstitutionManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("substitution manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
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

        func weightedExposure() -> Double {
            return (Double(startsAt) * Double(updatedAt) * 100).rounded() / 100
        }

        func copyValue() -> SubstitutionManifest {
            return SubstitutionManifest(
                code: code,
                title: title,
                discount: discount,
                label: label,
                attributes: attributes,
                updatedAt: updatedAt,
                amount: amount,
                ownerID: ownerID,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a substitution manifest in status draft.
    static func newSubstitutionManifest(_ code: String, title: String) -> SubstitutionManifest {
        return SubstitutionManifest(
            code: code,
            title: title,
            discount: 0.0,
            label: "",
            attributes: [:],
            updatedAt: 0,
            amount: 0.0,
            ownerID: "",
            startsAt: 0,
            status: SubstitutionManifestStatus.draft
        )
    }
}
