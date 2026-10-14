import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a denial manifest is in its life cycle.
    enum DenialManifestStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One denial manifest, with what the planners need to act on it.
    final class DenialManifest {
        var code: String
        var name: String
        var bed: String
        var category: String
        var dosageMg: Double
        var reviewer: String
        var patientRef: String
        var visible: Bool
        var currency: String
        var status: DenialManifestStatus

        init(code: String, name: String, bed: String, category: String, dosageMg: Double, reviewer: String, patientRef: String, visible: Bool, currency: String, status: DenialManifestStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.category = category
            self.dosageMg = dosageMg
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.visible = visible
            self.currency = currency
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

        func canMoveTo(_ next: DenialManifestStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DenialManifestStatus.resolved || next == DenialManifestStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == DenialManifestStatus.reopened
            case .reopened:
                return next == DenialManifestStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DenialManifestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("denial manifest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func measuredValue() -> Double {
            return dosageMg
        }

        func copyValue() -> DenialManifest {
            return DenialManifest(
                code: code,
                name: name,
                bed: bed,
                category: category,
                dosageMg: dosageMg,
                reviewer: reviewer,
                patientRef: patientRef,
                visible: visible,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a denial manifest in status open.
    static func newDenialManifest(_ code: String, name: String) -> DenialManifest {
        return DenialManifest(
            code: code,
            name: name,
            bed: "",
            category: "",
            dosageMg: 0.0,
            reviewer: "",
            patientRef: "",
            visible: false,
            currency: "",
            status: DenialManifestStatus.`open`
        )
    }
}
