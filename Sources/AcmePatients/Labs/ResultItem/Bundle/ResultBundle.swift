import AcmePlatform
import Foundation

extension Labs {
    /// Where a result bundle is in its life cycle.
    enum ResultBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a result bundle and its current status.
    final class ResultBundle {
        var code: String
        var title: String
        var ratio: Double
        var capacity: Int
        var quantity: Int
        var allergy: String
        var currency: String
        var version: Int
        var notes: String
        var status: ResultBundleStatus

        init(code: String, title: String, ratio: Double, capacity: Int, quantity: Int, allergy: String, currency: String, version: Int, notes: String, status: ResultBundleStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.capacity = capacity
            self.quantity = quantity
            self.allergy = allergy
            self.currency = currency
            self.version = version
            self.notes = notes
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultBundleStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ResultBundleStatus.rejected
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: ResultBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedValue() -> Double {
            return ((Double(quantity) - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> ResultBundle {
            return ResultBundle(
                code: code,
                title: title,
                ratio: ratio,
                capacity: capacity,
                quantity: quantity,
                allergy: allergy,
                currency: currency,
                version: version,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a result bundle in status proposed.
    static func newResultBundle(_ code: String, title: String) -> ResultBundle {
        return ResultBundle(
            code: code,
            title: title,
            ratio: 0.0,
            capacity: 0,
            quantity: 0,
            allergy: "",
            currency: "",
            version: 0,
            notes: "",
            status: ResultBundleStatus.proposed
        )
    }
}
