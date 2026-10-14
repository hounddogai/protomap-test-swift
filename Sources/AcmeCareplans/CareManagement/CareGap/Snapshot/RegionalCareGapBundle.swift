import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a regional care gap bundle is in its life cycle.
    enum RegionalCareGapBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A regional care gap bundle as the care gap team keeps it.
    final class RegionalCareGapBundle {
        var code: String
        var name: String
        var source: String
        var acuity: Int
        var externalRef: String
        var title: String
        var facility: String
        var status: RegionalCareGapBundleStatus

        init(code: String, name: String, source: String, acuity: Int, externalRef: String, title: String, facility: String, status: RegionalCareGapBundleStatus) {
            self.code = code
            self.name = name
            self.source = source
            self.acuity = acuity
            self.externalRef = externalRef
            self.title = title
            self.facility = facility
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

        func canMoveTo(_ next: RegionalCareGapBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == RegionalCareGapBundleStatus.revoked
            case .granted:
                return next == RegionalCareGapBundleStatus.revoked || next == RegionalCareGapBundleStatus.expired
            case .revoked:
                return next == RegionalCareGapBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalCareGapBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional care gap bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional care gap bundle") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> RegionalCareGapBundle {
            return RegionalCareGapBundle(
                code: code,
                name: name,
                source: source,
                acuity: acuity,
                externalRef: externalRef,
                title: title,
                facility: facility,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a regional care gap bundle in status requested.
    static func newRegionalCareGapBundle(_ code: String, name: String) -> RegionalCareGapBundle {
        return RegionalCareGapBundle(
            code: code,
            name: name,
            source: "",
            acuity: 0,
            externalRef: "",
            title: "",
            facility: "",
            status: RegionalCareGapBundleStatus.requested
        )
    }
}
