import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense segment is in its life cycle.
    enum DispenseSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A dispense segment as the dispense team keeps it.
    final class DispenseSegment {
        var code: String
        var name: String
        var pinned: Bool
        var version: Int
        var visitMinutes: Int
        var clinicianID: String
        var graceDays: Int
        var attempts: Int
        var active: Bool
        var locale: String
        var ceiling: Double
        var status: DispenseSegmentStatus

        init(code: String, name: String, pinned: Bool, version: Int, visitMinutes: Int, clinicianID: String, graceDays: Int, attempts: Int, active: Bool, locale: String, ceiling: Double, status: DispenseSegmentStatus) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.version = version
            self.visitMinutes = visitMinutes
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.attempts = attempts
            self.active = active
            self.locale = locale
            self.ceiling = ceiling
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DispenseSegmentStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == DispenseSegmentStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: DispenseSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("dispense segment") \(code)"
        }

        func weightedLoad() -> Double {
            return (Double(version) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> DispenseSegment {
            return DispenseSegment(
                code: code,
                name: name,
                pinned: pinned,
                version: version,
                visitMinutes: visitMinutes,
                clinicianID: clinicianID,
                graceDays: graceDays,
                attempts: attempts,
                active: active,
                locale: locale,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a dispense segment in status draft.
    static func newDispenseSegment(_ code: String, name: String) -> DispenseSegment {
        return DispenseSegment(
            code: code,
            name: name,
            pinned: false,
            version: 0,
            visitMinutes: 0,
            clinicianID: "",
            graceDays: 0,
            attempts: 0,
            active: false,
            locale: "",
            ceiling: 0.0,
            status: DispenseSegmentStatus.draft
        )
    }
}
