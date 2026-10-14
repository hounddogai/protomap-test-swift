import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global float pool summary is in its life cycle.
    enum GlobalFloatPoolSummaryStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a global float pool summary and its current status.
    final class GlobalFloatPoolSummary {
        var code: String
        var title: String
        var batchSize: Int
        var endsAt: Int
        var reviewer: String
        var cost: Double
        var ownerID: String
        var windowDays: Int
        var category: String
        var status: GlobalFloatPoolSummaryStatus

        init(code: String, title: String, batchSize: Int, endsAt: Int, reviewer: String, cost: Double, ownerID: String, windowDays: Int, category: String, status: GlobalFloatPoolSummaryStatus) {
            self.code = code
            self.title = title
            self.batchSize = batchSize
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.cost = cost
            self.ownerID = ownerID
            self.windowDays = windowDays
            self.category = category
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

        func canMoveTo(_ next: GlobalFloatPoolSummaryStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalFloatPoolSummaryStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalFloatPoolSummaryStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalFloatPoolSummaryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global float pool summary \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func weightedExposure() -> Double {
            return (cost * Double(windowDays) * 100).rounded() / 100
        }

        func copyValue() -> GlobalFloatPoolSummary {
            return GlobalFloatPoolSummary(
                code: code,
                title: title,
                batchSize: batchSize,
                endsAt: endsAt,
                reviewer: reviewer,
                cost: cost,
                ownerID: ownerID,
                windowDays: windowDays,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a global float pool summary in status requested.
    static func newGlobalFloatPoolSummary(_ code: String, title: String) -> GlobalFloatPoolSummary {
        return GlobalFloatPoolSummary(
            code: code,
            title: title,
            batchSize: 0,
            endsAt: 0,
            reviewer: "",
            cost: 0.0,
            ownerID: "",
            windowDays: 0,
            category: "",
            status: GlobalFloatPoolSummaryStatus.requested
        )
    }
}
