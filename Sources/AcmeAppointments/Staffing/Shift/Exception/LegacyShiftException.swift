import AcmePlatform
import Foundation

extension Staffing {
    /// Where a legacy shift exception is in its life cycle.
    enum LegacyShiftExceptionStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a legacy shift exception and its current status.
    final class LegacyShiftException {
        var code: String
        var name: String
        var clinicianID: String
        var margin: Double
        var dosageMg: Double
        var rate: Double
        var visitMinutes: Int
        var archived: Bool
        var status: LegacyShiftExceptionStatus

        init(code: String, name: String, clinicianID: String, margin: Double, dosageMg: Double, rate: Double, visitMinutes: Int, archived: Bool, status: LegacyShiftExceptionStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.margin = margin
            self.dosageMg = dosageMg
            self.rate = rate
            self.visitMinutes = visitMinutes
            self.archived = archived
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

        func canMoveTo(_ next: LegacyShiftExceptionStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyShiftExceptionStatus.reopened
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyShiftExceptionStatus.reopened || next == LegacyShiftExceptionStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyShiftExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy shift exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedVolume() -> Double {
            return (dosageMg * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> LegacyShiftException {
            return LegacyShiftException(
                code: code,
                name: name,
                clinicianID: clinicianID,
                margin: margin,
                dosageMg: dosageMg,
                rate: rate,
                visitMinutes: visitMinutes,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a legacy shift exception in status open.
    static func newLegacyShiftException(_ code: String, name: String) -> LegacyShiftException {
        return LegacyShiftException(
            code: code,
            name: name,
            clinicianID: "",
            margin: 0.0,
            dosageMg: 0.0,
            rate: 0.0,
            visitMinutes: 0,
            archived: false,
            status: LegacyShiftExceptionStatus.`open`
        )
    }
}
