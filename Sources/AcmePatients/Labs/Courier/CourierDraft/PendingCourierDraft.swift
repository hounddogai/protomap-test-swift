import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending courier draft is in its life cycle.
    enum PendingCourierDraftStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One pending courier draft, with what the planners need to act on it.
    final class PendingCourierDraft {
        var code: String
        var title: String
        var batchSize: Int
        var patientRef: String
        var rate: Double
        var refills: Int
        var windowDays: Int
        var procedureCode: String
        var durationMinutes: Int
        var startsAt: Int
        var status: PendingCourierDraftStatus

        init(code: String, title: String, batchSize: Int, patientRef: String, rate: Double, refills: Int, windowDays: Int, procedureCode: String, durationMinutes: Int, startsAt: Int, status: PendingCourierDraftStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.patientRef = patientRef
            self.rate = rate
            self.refills = refills
            self.windowDays = windowDays
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.startsAt = startsAt
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

        func canMoveTo(_ next: PendingCourierDraftStatus) -> Bool {
            switch status {
            case .new:
                return next == PendingCourierDraftStatus.running || next == PendingCourierDraftStatus.failed
            case .queued:
                return next == PendingCourierDraftStatus.failed
            case .running:
                return next == PendingCourierDraftStatus.done
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

        func moveTo(_ next: PendingCourierDraftStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending courier draft \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("pending courier draft") \(code)"
        }

        func weightedExposure() -> Double {
            return ((Double(windowDays) + Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> PendingCourierDraft {
            return PendingCourierDraft(
                code: code,
                title: title,
                batchSize: batchSize,
                patientRef: patientRef,
                rate: rate,
                refills: refills,
                windowDays: windowDays,
                procedureCode: procedureCode,
                durationMinutes: durationMinutes,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a pending courier draft in status new.
    static func newPendingCourierDraft(_ code: String, title: String) -> PendingCourierDraft {
        return PendingCourierDraft(
            code: code,
            title: title,
            batchSize: 0,
            patientRef: "",
            rate: 0.0,
            refills: 0,
            windowDays: 0,
            procedureCode: "",
            durationMinutes: 0,
            startsAt: 0,
            status: PendingCourierDraftStatus.new
        )
    }
}
