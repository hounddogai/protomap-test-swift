import AcmePlatform
import Foundation

extension Imaging {
    /// Where a lenient worklist exception is in its life cycle.
    enum LenientWorklistExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A lenient worklist exception as the worklist team keeps it.
    final class LenientWorklistException {
        var code: String
        var title: String
        var reviewer: String
        var floorValue: Double
        var batchSize: Int
        var durationMinutes: Int
        var description: String
        var revision: Int
        var visitMinutes: Int
        var quantity: Int
        var timezone: String
        var status: LenientWorklistExceptionStatus

        init(code: String, title: String, reviewer: String, floorValue: Double, batchSize: Int, durationMinutes: Int, description: String, revision: Int, visitMinutes: Int, quantity: Int, timezone: String, status: LenientWorklistExceptionStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.floorValue = floorValue
            self.batchSize = batchSize
            self.durationMinutes = durationMinutes
            self.description = description
            self.revision = revision
            self.visitMinutes = visitMinutes
            self.quantity = quantity
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientWorklistExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LenientWorklistExceptionStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: LenientWorklistExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient worklist exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("lenient worklist exception") \(code)"
        }

        func weightedTotal() -> Double {
            return ((Double(batchSize) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> LenientWorklistException {
            return LenientWorklistException(
                code: code,
                title: title,
                reviewer: reviewer,
                floorValue: floorValue,
                batchSize: batchSize,
                durationMinutes: durationMinutes,
                description: description,
                revision: revision,
                visitMinutes: visitMinutes,
                quantity: quantity,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient worklist exception in status idle.
    static func newLenientWorklistException(_ code: String, title: String) -> LenientWorklistException {
        return LenientWorklistException(
            code: code,
            title: title,
            reviewer: "",
            floorValue: 0.0,
            batchSize: 0,
            durationMinutes: 0,
            description: "",
            revision: 0,
            visitMinutes: 0,
            quantity: 0,
            timezone: "",
            status: LenientWorklistExceptionStatus.idle
        )
    }
}
