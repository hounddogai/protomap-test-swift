import AcmePlatform
import Foundation

extension Labs {
    /// Where a adaptive accession bundle is in its life cycle.
    enum AdaptiveAccessionBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One adaptive accession bundle, with what the planners need to act on it.
    final class AdaptiveAccessionBundle {
        var code: String
        var label: String
        var updatedAt: Int
        var allergy: String
        var bed: String
        var status: AdaptiveAccessionBundleStatus

        init(code: String, label: String, updatedAt: Int, allergy: String, bed: String, status: AdaptiveAccessionBundleStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.allergy = allergy
            self.bed = bed
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

        func canMoveTo(_ next: AdaptiveAccessionBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveAccessionBundleStatus.granted || next == AdaptiveAccessionBundleStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == AdaptiveAccessionBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveAccessionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive accession bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return Double(updatedAt)
        }

        func copyValue() -> AdaptiveAccessionBundle {
            return AdaptiveAccessionBundle(
                code: code,
                label: label,
                updatedAt: updatedAt,
                allergy: allergy,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive accession bundle in status requested.
    static func newAdaptiveAccessionBundle(_ code: String, label: String) -> AdaptiveAccessionBundle {
        return AdaptiveAccessionBundle(
            code: code,
            label: label,
            updatedAt: 0,
            allergy: "",
            bed: "",
            status: AdaptiveAccessionBundleStatus.requested
        )
    }
}
