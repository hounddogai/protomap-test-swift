import AcmePlatform
import Foundation

extension Imaging {
    /// Where a adaptive care protocol threshold is in its life cycle.
    enum AdaptiveCareProtocolThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a adaptive care protocol threshold and its current status.
    final class AdaptiveCareProtocolThreshold {
        var code: String
        var title: String
        var updatedAt: Int
        var category: String
        var graceDays: Int
        var checksum: String
        var ratio: Double
        var visitMinutes: Int
        var createdAt: Int
        var cost: Double
        var status: AdaptiveCareProtocolThresholdStatus

        init(code: String, title: String, updatedAt: Int, category: String, graceDays: Int, checksum: String, ratio: Double, visitMinutes: Int, createdAt: Int, cost: Double, status: AdaptiveCareProtocolThresholdStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.category = category
            self.graceDays = graceDays
            self.checksum = checksum
            self.ratio = ratio
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.cost = cost
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

        func canMoveTo(_ next: AdaptiveCareProtocolThresholdStatus) -> Bool {
            switch status {
            case .draft:
                return next == AdaptiveCareProtocolThresholdStatus.pending || next == AdaptiveCareProtocolThresholdStatus.closed
            case .pending:
                return next == AdaptiveCareProtocolThresholdStatus.closed
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == AdaptiveCareProtocolThresholdStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveCareProtocolThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care protocol threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func netLoad() -> Double {
            return ((Double(updatedAt) + Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareProtocolThreshold {
            return AdaptiveCareProtocolThreshold(
                code: code,
                title: title,
                updatedAt: updatedAt,
                category: category,
                graceDays: graceDays,
                checksum: checksum,
                ratio: ratio,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive care protocol threshold in status draft.
    static func newAdaptiveCareProtocolThreshold(_ code: String, title: String) -> AdaptiveCareProtocolThreshold {
        return AdaptiveCareProtocolThreshold(
            code: code,
            title: title,
            updatedAt: 0,
            category: "",
            graceDays: 0,
            checksum: "",
            ratio: 0.0,
            visitMinutes: 0,
            createdAt: 0,
            cost: 0.0,
            status: AdaptiveCareProtocolThresholdStatus.draft
        )
    }
}
