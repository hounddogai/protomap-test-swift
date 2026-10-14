import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled care protocol profile is in its life cycle.
    enum ScheduledCareProtocolProfileStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One scheduled care protocol profile, with what the planners need to act on it.
    final class ScheduledCareProtocolProfile {
        var code: String
        var name: String
        var refills: Int
        var batchSize: Int
        var score: Double
        var country: String
        var visitMinutes: Int
        var patientRef: String
        var status: ScheduledCareProtocolProfileStatus

        init(code: String, name: String, refills: Int, batchSize: Int, score: Double, country: String, visitMinutes: Int, patientRef: String, status: ScheduledCareProtocolProfileStatus) {
            self.code = code
            self.name = name
            self.refills = refills
            self.batchSize = batchSize
            self.score = score
            self.country = country
            self.visitMinutes = visitMinutes
            self.patientRef = patientRef
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

        func canMoveTo(_ next: ScheduledCareProtocolProfileStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ScheduledCareProtocolProfileStatus.reopened || next == ScheduledCareProtocolProfileStatus.archived
            case .inReview:
                return next == ScheduledCareProtocolProfileStatus.resolved || next == ScheduledCareProtocolProfileStatus.reopened
            case .resolved:
                return next == ScheduledCareProtocolProfileStatus.reopened || next == ScheduledCareProtocolProfileStatus.archived
            case .reopened:
                return next == ScheduledCareProtocolProfileStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledCareProtocolProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled care protocol profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func effectiveTotal() -> Double {
            return ((Double(refills) - score) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledCareProtocolProfile {
            return ScheduledCareProtocolProfile(
                code: code,
                name: name,
                refills: refills,
                batchSize: batchSize,
                score: score,
                country: country,
                visitMinutes: visitMinutes,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a scheduled care protocol profile in status open.
    static func newScheduledCareProtocolProfile(_ code: String, name: String) -> ScheduledCareProtocolProfile {
        return ScheduledCareProtocolProfile(
            code: code,
            name: name,
            refills: 0,
            batchSize: 0,
            score: 0.0,
            country: "",
            visitMinutes: 0,
            patientRef: "",
            status: ScheduledCareProtocolProfileStatus.`open`
        )
    }
}
