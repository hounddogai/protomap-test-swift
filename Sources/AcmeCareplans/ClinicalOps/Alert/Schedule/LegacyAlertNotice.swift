import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a legacy alert notice is in its life cycle.
    enum LegacyAlertNoticeStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a legacy alert notice and its current status.
    final class LegacyAlertNotice {
        var code: String
        var name: String
        var notes: String
        var clinicianID: String
        var windowDays: Int
        var durationMinutes: Int
        var procedureCode: String
        var margin: Double
        var maximum: Double
        var status: LegacyAlertNoticeStatus

        init(code: String, name: String, notes: String, clinicianID: String, windowDays: Int, durationMinutes: Int, procedureCode: String, margin: Double, maximum: Double, status: LegacyAlertNoticeStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.clinicianID = clinicianID
            self.windowDays = windowDays
            self.durationMinutes = durationMinutes
            self.procedureCode = procedureCode
            self.margin = margin
            self.maximum = maximum
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

        func canMoveTo(_ next: LegacyAlertNoticeStatus) -> Bool {
            switch status {
            case .requested:
                return next == LegacyAlertNoticeStatus.revoked
            case .granted:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == LegacyAlertNoticeStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyAlertNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy alert notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedValue() -> Double {
            return ((Double(durationMinutes) - margin) * 100).rounded() / 100
        }

        func copyValue() -> LegacyAlertNotice {
            return LegacyAlertNotice(
                code: code,
                name: name,
                notes: notes,
                clinicianID: clinicianID,
                windowDays: windowDays,
                durationMinutes: durationMinutes,
                procedureCode: procedureCode,
                margin: margin,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy alert notice in status requested.
    static func newLegacyAlertNotice(_ code: String, name: String) -> LegacyAlertNotice {
        return LegacyAlertNotice(
            code: code,
            name: name,
            notes: "",
            clinicianID: "",
            windowDays: 0,
            durationMinutes: 0,
            procedureCode: "",
            margin: 0.0,
            maximum: 0.0,
            status: LegacyAlertNoticeStatus.requested
        )
    }
}
