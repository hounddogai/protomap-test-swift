import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set reservation is in its life cycle.
    enum OrderSetReservationStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One order set reservation, with what the planners need to act on it.
    final class OrderSetReservation {
        var code: String
        var label: String
        var checksum: String
        var source: String
        var title: String
        var attributes: [String: String]
        var ratio: Double
        var locale: String
        var description: String
        var category: String
        var discount: Double
        var status: OrderSetReservationStatus

        init(code: String, label: String, checksum: String, source: String, title: String, attributes: [String: String], ratio: Double, locale: String, description: String, category: String, discount: Double, status: OrderSetReservationStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.source = source
            self.title = title
            self.attributes = attributes
            self.ratio = ratio
            self.locale = locale
            self.description = description
            self.category = category
            self.discount = discount
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

        func canMoveTo(_ next: OrderSetReservationStatus) -> Bool {
            switch status {
            case .planned:
                return next == OrderSetReservationStatus.scheduled || next == OrderSetReservationStatus.inProgress
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == OrderSetReservationStatus.completed || next == OrderSetReservationStatus.cancelled
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

        func moveTo(_ next: OrderSetReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("order set reservation") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func adjustedExposure() -> Double {
            return (ratio * discount * 100).rounded() / 100
        }

        func copyValue() -> OrderSetReservation {
            return OrderSetReservation(
                code: code,
                label: label,
                checksum: checksum,
                source: source,
                title: title,
                attributes: attributes,
                ratio: ratio,
                locale: locale,
                description: description,
                category: category,
                discount: discount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a order set reservation in status planned.
    static func newOrderSetReservation(_ code: String, label: String) -> OrderSetReservation {
        return OrderSetReservation(
            code: code,
            label: label,
            checksum: "",
            source: "",
            title: "",
            attributes: [:],
            ratio: 0.0,
            locale: "",
            description: "",
            category: "",
            discount: 0.0,
            status: OrderSetReservationStatus.planned
        )
    }
}
