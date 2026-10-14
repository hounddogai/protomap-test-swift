import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a seasonal program bundle is in its life cycle.
    enum SeasonalProgramBundleStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One seasonal program bundle, with what the planners need to act on it.
    final class SeasonalProgramBundle {
        var code: String
        var title: String
        var limit: Int
        var description: String
        var active: Bool
        var unit: String
        var facility: String
        var payer: String
        var status: SeasonalProgramBundleStatus

        init(code: String, title: String, limit: Int, description: String, active: Bool, unit: String, facility: String, payer: String, status: SeasonalProgramBundleStatus) {
            self.code = code
            self.title = title
            self.limit = limit
            self.description = description
            self.active = active
            self.unit = unit
            self.facility = facility
            self.payer = payer
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

        func canMoveTo(_ next: SeasonalProgramBundleStatus) -> Bool {
            switch status {
            case .requested:
                return next == SeasonalProgramBundleStatus.granted || next == SeasonalProgramBundleStatus.expired
            case .granted:
                return next == SeasonalProgramBundleStatus.revoked || next == SeasonalProgramBundleStatus.expired
            case .revoked:
                return next == SeasonalProgramBundleStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalProgramBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal program bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> SeasonalProgramBundle {
            return SeasonalProgramBundle(
                code: code,
                title: title,
                limit: limit,
                description: description,
                active: active,
                unit: unit,
                facility: facility,
                payer: payer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal program bundle in status requested.
    static func newSeasonalProgramBundle(_ code: String, title: String) -> SeasonalProgramBundle {
        return SeasonalProgramBundle(
            code: code,
            title: title,
            limit: 0,
            description: "",
            active: false,
            unit: "",
            facility: "",
            payer: "",
            status: SeasonalProgramBundleStatus.requested
        )
    }
}
