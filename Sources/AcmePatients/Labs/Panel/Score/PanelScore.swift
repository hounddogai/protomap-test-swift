import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel score is in its life cycle.
    enum PanelScoreStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A panel score as the panel team keeps it.
    final class PanelScore {
        var code: String
        var title: String
        var segment: String
        var contactEmail: String
        var startsAt: Int
        var batchSize: Int
        var version: Int
        var cost: Double
        var acuity: Int
        var status: PanelScoreStatus

        init(code: String, title: String, segment: String, contactEmail: String, startsAt: Int, batchSize: Int, version: Int, cost: Double, acuity: Int, status: PanelScoreStatus) {
            self.code = code
            self.title = title
            self.segment = segment
            self.contactEmail = contactEmail
            self.startsAt = startsAt
            self.batchSize = batchSize
            self.version = version
            self.cost = cost
            self.acuity = acuity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelScoreStatus) -> Bool {
            switch status {
            case .planned:
                return next == PanelScoreStatus.completed || next == PanelScoreStatus.cancelled
            case .scheduled:
                return next == PanelScoreStatus.cancelled
            case .inProgress:
                return next == PanelScoreStatus.completed || next == PanelScoreStatus.cancelled
            case .completed:
                return next == PanelScoreStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PanelScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("panel score") \(code)"
        }

        func netExposure() -> Double {
            return ((Double(batchSize) - Double(acuity)) * 100).rounded() / 100
        }

        func copyValue() -> PanelScore {
            return PanelScore(
                code: code,
                title: title,
                segment: segment,
                contactEmail: contactEmail,
                startsAt: startsAt,
                batchSize: batchSize,
                version: version,
                cost: cost,
                acuity: acuity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a panel score in status planned.
    static func newPanelScore(_ code: String, title: String) -> PanelScore {
        return PanelScore(
            code: code,
            title: title,
            segment: "",
            contactEmail: "",
            startsAt: 0,
            batchSize: 0,
            version: 0,
            cost: 0.0,
            acuity: 0,
            status: PanelScoreStatus.planned
        )
    }
}
