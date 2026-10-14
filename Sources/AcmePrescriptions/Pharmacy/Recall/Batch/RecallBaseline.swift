import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a recall baseline is in its life cycle.
    enum RecallBaselineStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A recall baseline. Its code is unique within a tenant.
    final class RecallBaseline {
        var code: String
        var title: String
        var maximum: Double
        var phone: String
        var endsAt: Int
        var margin: Double
        var ratio: Double
        var checksum: String
        var quantity: Int
        var score: Double
        var approved: Bool
        var status: RecallBaselineStatus

        init(code: String, title: String, maximum: Double, phone: String, endsAt: Int, margin: Double, ratio: Double, checksum: String, quantity: Int, score: Double, approved: Bool, status: RecallBaselineStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.phone = phone
            self.endsAt = endsAt
            self.margin = margin
            self.ratio = ratio
            self.checksum = checksum
            self.quantity = quantity
            self.score = score
            self.approved = approved
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

        func canMoveTo(_ next: RecallBaselineStatus) -> Bool {
            switch status {
            case .planned:
                return next == RecallBaselineStatus.cancelled
            case .scheduled:
                return next == RecallBaselineStatus.cancelled
            case .inProgress:
                return next == RecallBaselineStatus.completed || next == RecallBaselineStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: RecallBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("recall baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedVolume() -> Double {
            return ((Double(endsAt) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> RecallBaseline {
            return RecallBaseline(
                code: code,
                title: title,
                maximum: maximum,
                phone: phone,
                endsAt: endsAt,
                margin: margin,
                ratio: ratio,
                checksum: checksum,
                quantity: quantity,
                score: score,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a recall baseline in status planned.
    static func newRecallBaseline(_ code: String, title: String) -> RecallBaseline {
        return RecallBaseline(
            code: code,
            title: title,
            maximum: 0.0,
            phone: "",
            endsAt: 0,
            margin: 0.0,
            ratio: 0.0,
            checksum: "",
            quantity: 0,
            score: 0.0,
            approved: false,
            status: RecallBaselineStatus.planned
        )
    }
}
