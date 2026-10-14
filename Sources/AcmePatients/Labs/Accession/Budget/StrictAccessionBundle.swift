import AcmePlatform
import Foundation

extension Labs {
    /// Where a strict accession bundle is in its life cycle.
    enum StrictAccessionBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a strict accession bundle and its current status.
    final class StrictAccessionBundle {
        var code: String
        var name: String
        var visible: Bool
        var patientRef: String
        var visitMinutes: Int
        var startsAt: Int
        var bed: String
        var locale: String
        var status: StrictAccessionBundleStatus

        init(code: String, name: String, visible: Bool, patientRef: String, visitMinutes: Int, startsAt: Int, bed: String, locale: String, status: StrictAccessionBundleStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.startsAt = startsAt
            self.bed = bed
            self.locale = locale
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

        func canMoveTo(_ next: StrictAccessionBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == StrictAccessionBundleStatus.expired
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == StrictAccessionBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictAccessionBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict accession bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return ((Double(visitMinutes) + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> StrictAccessionBundle {
            return StrictAccessionBundle(
                code: code,
                name: name,
                visible: visible,
                patientRef: patientRef,
                visitMinutes: visitMinutes,
                startsAt: startsAt,
                bed: bed,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a strict accession bundle in status requested.
    static func newStrictAccessionBundle(_ code: String, name: String) -> StrictAccessionBundle {
        return StrictAccessionBundle(
            code: code,
            name: name,
            visible: false,
            patientRef: "",
            visitMinutes: 0,
            startsAt: 0,
            bed: "",
            locale: "",
            status: StrictAccessionBundleStatus.requested
        )
    }
}
