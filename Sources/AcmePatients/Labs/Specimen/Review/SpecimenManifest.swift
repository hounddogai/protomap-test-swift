import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen manifest is in its life cycle.
    enum SpecimenManifestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One specimen manifest, with what the planners need to act on it.
    final class SpecimenManifest {
        var code: String
        var label: String
        var country: String
        var refills: Int
        var attempts: Int
        var status: SpecimenManifestStatus

        init(code: String, label: String, country: String, refills: Int, attempts: Int, status: SpecimenManifestStatus) {
            self.code = code
            self.label = label
            self.country = country
            self.refills = refills
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SpecimenManifestStatus) -> Bool {
            switch status {
            case .created:
                return next == SpecimenManifestStatus.validated || next == SpecimenManifestStatus.published
            case .validated:
                return next == SpecimenManifestStatus.retired
            case .published:
                return next == SpecimenManifestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveLoad() -> Double {
            return ((Double(refills) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenManifest {
            return SpecimenManifest(
                code: code,
                label: label,
                country: country,
                refills: refills,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a specimen manifest in status created.
    static func newSpecimenManifest(_ code: String, label: String) -> SpecimenManifest {
        return SpecimenManifest(
            code: code,
            label: label,
            country: "",
            refills: 0,
            attempts: 0,
            status: SpecimenManifestStatus.created
        )
    }
}
