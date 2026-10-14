import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a lenient formulary audit is in its life cycle.
    enum LenientFormularyAuditStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient formulary audit. Its code is unique within a tenant.
    final class LenientFormularyAudit {
        var code: String
        var name: String
        var checksum: String
        var specialty: String
        var durationMinutes: Int
        var status: LenientFormularyAuditStatus

        init(code: String, name: String, checksum: String, specialty: String, durationMinutes: Int, status: LenientFormularyAuditStatus) {
            self.code = code
            self.name = name
            self.checksum = checksum
            self.specialty = specialty
            self.durationMinutes = durationMinutes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientFormularyAuditStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == LenientFormularyAuditStatus.done || next == LenientFormularyAuditStatus.failed
            case .running:
                return next == LenientFormularyAuditStatus.done || next == LenientFormularyAuditStatus.failed
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: LenientFormularyAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient formulary audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient formulary audit") \(code)"
        }

        func measuredValue() -> Double {
            return Double(durationMinutes)
        }

        func copyValue() -> LenientFormularyAudit {
            return LenientFormularyAudit(
                code: code,
                name: name,
                checksum: checksum,
                specialty: specialty,
                durationMinutes: durationMinutes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a lenient formulary audit in status new.
    static func newLenientFormularyAudit(_ code: String, name: String) -> LenientFormularyAudit {
        return LenientFormularyAudit(
            code: code,
            name: name,
            checksum: "",
            specialty: "",
            durationMinutes: 0,
            status: LenientFormularyAuditStatus.new
        )
    }
}
