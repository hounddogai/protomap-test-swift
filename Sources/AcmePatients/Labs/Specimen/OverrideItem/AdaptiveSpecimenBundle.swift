import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive specimen bundle is in its life cycle.
    enum AdaptiveSpecimenBundleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One adaptive specimen bundle, with what the planners need to act on it.
    final class AdaptiveSpecimenBundle {
        var code: String
        var label: String
        var bed: String
        var currency: String
        var graceDays: Int
        var procedureCode: String
        var unit: String
        var title: String
        var expiresAt: Int
        var status: AdaptiveSpecimenBundleStatus

        init(code: String, label: String, bed: String, currency: String, graceDays: Int, procedureCode: String, unit: String, title: String, expiresAt: Int, status: AdaptiveSpecimenBundleStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.currency = currency
            self.graceDays = graceDays
            self.procedureCode = procedureCode
            self.unit = unit
            self.title = title
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: AdaptiveSpecimenBundleStatus) -> Bool {
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
                case .resolved, .archived:
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
                return next == AdaptiveSpecimenBundleStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveSpecimenBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive specimen bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedExposure() -> Double {
            return ((Double(graceDays) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveSpecimenBundle {
            return AdaptiveSpecimenBundle(
                code: code,
                label: label,
                bed: bed,
                currency: currency,
                graceDays: graceDays,
                procedureCode: procedureCode,
                unit: unit,
                title: title,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive specimen bundle in status open.
    static func newAdaptiveSpecimenBundle(_ code: String, label: String) -> AdaptiveSpecimenBundle {
        return AdaptiveSpecimenBundle(
            code: code,
            label: label,
            bed: "",
            currency: "",
            graceDays: 0,
            procedureCode: "",
            unit: "",
            title: "",
            expiresAt: 0,
            status: AdaptiveSpecimenBundleStatus.`open`
        )
    }
}
