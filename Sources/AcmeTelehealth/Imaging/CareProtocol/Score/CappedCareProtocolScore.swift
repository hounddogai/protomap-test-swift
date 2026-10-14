import AcmePlatform
import Foundation

extension Imaging {
    /// Where a capped care protocol score is in its life cycle.
    enum CappedCareProtocolScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A capped care protocol score as the care protocol team keeps it.
    final class CappedCareProtocolScore {
        var code: String
        var title: String
        var floorValue: Double
        var attempts: Int
        var diagnosisCode: String
        var summary: String
        var startsAt: Int
        var status: CappedCareProtocolScoreStatus

        init(code: String, title: String, floorValue: Double, attempts: Int, diagnosisCode: String, summary: String, startsAt: Int, status: CappedCareProtocolScoreStatus) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.startsAt = startsAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedCareProtocolScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == CappedCareProtocolScoreStatus.published || next == CappedCareProtocolScoreStatus.retired
            case .validated:
                return next == CappedCareProtocolScoreStatus.published || next == CappedCareProtocolScoreStatus.retired
            case .published:
                return next == CappedCareProtocolScoreStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedCareProtocolScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped care protocol score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func projectedExposure() -> Double {
            return (Double(attempts) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> CappedCareProtocolScore {
            return CappedCareProtocolScore(
                code: code,
                title: title,
                floorValue: floorValue,
                attempts: attempts,
                diagnosisCode: diagnosisCode,
                summary: summary,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped care protocol score in status created.
    static func newCappedCareProtocolScore(_ code: String, title: String) -> CappedCareProtocolScore {
        return CappedCareProtocolScore(
            code: code,
            title: title,
            floorValue: 0.0,
            attempts: 0,
            diagnosisCode: "",
            summary: "",
            startsAt: 0,
            status: CappedCareProtocolScoreStatus.created
        )
    }
}
