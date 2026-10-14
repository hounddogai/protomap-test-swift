import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a lenient program profile is in its life cycle.
    enum LenientProgramProfileStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A lenient program profile as the program team keeps it.
    final class LenientProgramProfile {
        var code: String
        var title: String
        var patientRef: String
        var acuity: Int
        var approved: Bool
        var status: LenientProgramProfileStatus

        init(code: String, title: String, patientRef: String, acuity: Int, approved: Bool, status: LenientProgramProfileStatus) {
            self.code = code
            self.title = title
            self.patientRef = patientRef
            self.acuity = acuity
            self.approved = approved
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

        func canMoveTo(_ next: LenientProgramProfileStatus) -> Bool {
            switch status {
            case .new:
                return next == LenientProgramProfileStatus.queued || next == LenientProgramProfileStatus.done
            case .queued:
                return next == LenientProgramProfileStatus.running || next == LenientProgramProfileStatus.failed
            case .running:
                return next == LenientProgramProfileStatus.done || next == LenientProgramProfileStatus.failed
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

        func moveTo(_ next: LenientProgramProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient program profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("lenient program profile") \(code)"
        }

        func measuredValue() -> Double {
            return Double(acuity)
        }

        func copyValue() -> LenientProgramProfile {
            return LenientProgramProfile(
                code: code,
                title: title,
                patientRef: patientRef,
                acuity: acuity,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient program profile in status new.
    static func newLenientProgramProfile(_ code: String, title: String) -> LenientProgramProfile {
        return LenientProgramProfile(
            code: code,
            title: title,
            patientRef: "",
            acuity: 0,
            approved: false,
            status: LenientProgramProfileStatus.new
        )
    }
}
