import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession manifest is in its life cycle.
    enum AccessionManifestStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One accession manifest, with what the planners need to act on it.
    final class AccessionManifest {
        var code: String
        var label: String
        var country: String
        var bed: String
        var tags: [String]
        var minimum: Double
        var notes: String
        var amount: Double
        var acuity: Int
        var status: AccessionManifestStatus

        init(code: String, label: String, country: String, bed: String, tags: [String], minimum: Double, notes: String, amount: Double, acuity: Int, status: AccessionManifestStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.bed = bed
            self.tags = tags
            self.minimum = minimum
            self.notes = notes
            self.amount = amount
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AccessionManifestStatus) -> Bool {
            switch status {
            case .requested:
                return next == AccessionManifestStatus.revoked
            case .granted:
                return next == AccessionManifestStatus.expired
            case .revoked:
                return next == AccessionManifestStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netLoad() -> Double {
            return ((minimum - amount) * 100).rounded() / 100
        }

        func copyValue() -> AccessionManifest {
            return AccessionManifest(
                code: code,
                label: label,
                country: country,
                bed: bed,
                tags: tags,
                minimum: minimum,
                notes: notes,
                amount: amount,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a accession manifest in status requested.
    static func newAccessionManifest(_ code: String, label: String) -> AccessionManifest {
        return AccessionManifest(
            code: code,
            label: label,
            country: "",
            bed: "",
            tags: [],
            minimum: 0.0,
            notes: "",
            amount: 0.0,
            acuity: 0,
            status: AccessionManifestStatus.requested
        )
    }
}
