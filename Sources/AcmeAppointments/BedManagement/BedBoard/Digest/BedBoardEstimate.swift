import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board estimate is in its life cycle.
    enum BedBoardEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a bed board estimate and its current status.
    final class BedBoardEstimate {
        var code: String
        var title: String
        var maximum: Double
        var approved: Bool
        var margin: Double
        var createdAt: Int
        var label: String
        var rate: Double
        var channel: String
        var priority: Int
        var status: BedBoardEstimateStatus

        init(code: String, title: String, maximum: Double, approved: Bool, margin: Double, createdAt: Int, label: String, rate: Double, channel: String, priority: Int, status: BedBoardEstimateStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.approved = approved
            self.margin = margin
            self.createdAt = createdAt
            self.label = label
            self.rate = rate
            self.channel = channel
            self.priority = priority
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

        func canMoveTo(_ next: BedBoardEstimateStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == BedBoardEstimateStatus.closed
            case .active:
                return next == BedBoardEstimateStatus.suspended || next == BedBoardEstimateStatus.closed
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

        func moveTo(_ next: BedBoardEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((Double(priority) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardEstimate {
            return BedBoardEstimate(
                code: code,
                title: title,
                maximum: maximum,
                approved: approved,
                margin: margin,
                createdAt: createdAt,
                label: label,
                rate: rate,
                channel: channel,
                priority: priority,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a bed board estimate in status draft.
    static func newBedBoardEstimate(_ code: String, title: String) -> BedBoardEstimate {
        return BedBoardEstimate(
            code: code,
            title: title,
            maximum: 0.0,
            approved: false,
            margin: 0.0,
            createdAt: 0,
            label: "",
            rate: 0.0,
            channel: "",
            priority: 0,
            status: BedBoardEstimateStatus.draft
        )
    }
}
