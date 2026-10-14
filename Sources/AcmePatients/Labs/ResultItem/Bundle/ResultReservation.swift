import AcmePlatform
import Foundation

extension Labs {
    /// Where a result reservation is in its life cycle.
    enum ResultReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a result reservation and its current status.
    final class ResultReservation {
        var code: String
        var label: String
        var tags: [String]
        var amount: Double
        var category: String
        var archived: Bool
        var status: ResultReservationStatus

        init(code: String, label: String, tags: [String], amount: Double, category: String, archived: Bool, status: ResultReservationStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.amount = amount
            self.category = category
            self.archived = archived
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

        func canMoveTo(_ next: ResultReservationStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ResultReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> ResultReservation {
            return ResultReservation(
                code: code,
                label: label,
                tags: tags,
                amount: amount,
                category: category,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a result reservation in status new.
    static func newResultReservation(_ code: String, label: String) -> ResultReservation {
        return ResultReservation(
            code: code,
            label: label,
            tags: [],
            amount: 0.0,
            category: "",
            archived: false,
            status: ResultReservationStatus.new
        )
    }
}
