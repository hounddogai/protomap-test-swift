import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range exception is in its life cycle.
    enum ReferenceRangeExceptionStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a reference range exception and its current status.
    final class ReferenceRangeException {
        var code: String
        var name: String
        var description: String
        var ratio: Double
        var quantity: Int
        var category: String
        var attributes: [String: String]
        var country: String
        var version: Int
        var capacity: Int
        var status: ReferenceRangeExceptionStatus

        init(code: String, name: String, description: String, ratio: Double, quantity: Int, category: String, attributes: [String: String], country: String, version: Int, capacity: Int, status: ReferenceRangeExceptionStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.ratio = ratio
            self.quantity = quantity
            self.category = category
            self.attributes = attributes
            self.country = country
            self.version = version
            self.capacity = capacity
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

        func canMoveTo(_ next: ReferenceRangeExceptionStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ReferenceRangeExceptionStatus.rejected || next == ReferenceRangeExceptionStatus.withdrawn
            case .approved:
                return next == ReferenceRangeExceptionStatus.rejected
            case .rejected:
                return next == ReferenceRangeExceptionStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferenceRangeExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("reference range exception") \(code)"
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

        func projectedTotal() -> Double {
            return ((Double(version) + Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeException {
            return ReferenceRangeException(
                code: code,
                name: name,
                description: description,
                ratio: ratio,
                quantity: quantity,
                category: category,
                attributes: attributes,
                country: country,
                version: version,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a reference range exception in status proposed.
    static func newReferenceRangeException(_ code: String, name: String) -> ReferenceRangeException {
        return ReferenceRangeException(
            code: code,
            name: name,
            description: "",
            ratio: 0.0,
            quantity: 0,
            category: "",
            attributes: [:],
            country: "",
            version: 0,
            capacity: 0,
            status: ReferenceRangeExceptionStatus.proposed
        )
    }
}
