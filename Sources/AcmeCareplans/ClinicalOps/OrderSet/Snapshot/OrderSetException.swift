import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set exception is in its life cycle.
    enum OrderSetExceptionStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One order set exception, with what the planners need to act on it.
    final class OrderSetException {
        var code: String
        var title: String
        var notes: String
        var summary: String
        var ratio: Double
        var clinicianID: String
        var graceDays: Int
        var locale: String
        var status: OrderSetExceptionStatus

        init(code: String, title: String, notes: String, summary: String, ratio: Double, clinicianID: String, graceDays: Int, locale: String, status: OrderSetExceptionStatus) {
            self.code = code
            self.title = title
            self.notes = notes
            self.summary = summary
            self.ratio = ratio
            self.clinicianID = clinicianID
            self.graceDays = graceDays
            self.locale = locale
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

        func canMoveTo(_ next: OrderSetExceptionStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: OrderSetExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((Double(graceDays) - ratio) * 100).rounded() / 100
        }

        func copyValue() -> OrderSetException {
            return OrderSetException(
                code: code,
                title: title,
                notes: notes,
                summary: summary,
                ratio: ratio,
                clinicianID: clinicianID,
                graceDays: graceDays,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a order set exception in status created.
    static func newOrderSetException(_ code: String, title: String) -> OrderSetException {
        return OrderSetException(
            code: code,
            title: title,
            notes: "",
            summary: "",
            ratio: 0.0,
            clinicianID: "",
            graceDays: 0,
            locale: "",
            status: OrderSetExceptionStatus.created
        )
    }
}
