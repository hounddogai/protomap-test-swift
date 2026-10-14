import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a default alert entry is in its life cycle.
    enum DefaultAlertEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a default alert entry and its current status.
    final class DefaultAlertEntry {
        var code: String
        var title: String
        var budget: Double
        var ward: String
        var attributes: [String: String]
        var capacity: Int
        var refills: Int
        var facility: String
        var pinned: Bool
        var margin: Double
        var status: DefaultAlertEntryStatus

        init(code: String, title: String, budget: Double, ward: String, attributes: [String: String], capacity: Int, refills: Int, facility: String, pinned: Bool, margin: Double, status: DefaultAlertEntryStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.ward = ward
            self.attributes = attributes
            self.capacity = capacity
            self.refills = refills
            self.facility = facility
            self.pinned = pinned
            self.margin = margin
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

        func canMoveTo(_ next: DefaultAlertEntryStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultAlertEntryStatus.inProgress
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultAlertEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default alert entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default alert entry") \(code)"
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

        func netExposure() -> Double {
            return ((Double(capacity) + margin) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAlertEntry {
            return DefaultAlertEntry(
                code: code,
                title: title,
                budget: budget,
                ward: ward,
                attributes: attributes,
                capacity: capacity,
                refills: refills,
                facility: facility,
                pinned: pinned,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a default alert entry in status planned.
    static func newDefaultAlertEntry(_ code: String, title: String) -> DefaultAlertEntry {
        return DefaultAlertEntry(
            code: code,
            title: title,
            budget: 0.0,
            ward: "",
            attributes: [:],
            capacity: 0,
            refills: 0,
            facility: "",
            pinned: false,
            margin: 0.0,
            status: DefaultAlertEntryStatus.planned
        )
    }
}
