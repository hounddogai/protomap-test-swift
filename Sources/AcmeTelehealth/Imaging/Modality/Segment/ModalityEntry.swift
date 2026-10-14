import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality entry is in its life cycle.
    enum ModalityEntryStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A modality entry. Its code is unique within a tenant.
    final class ModalityEntry {
        var code: String
        var label: String
        var region: String
        var externalRef: String
        var phone: String
        var margin: Double
        var timezone: String
        var priority: Int
        var specialty: String
        var minimum: Double
        var description: String
        var status: ModalityEntryStatus

        init(code: String, label: String, region: String, externalRef: String, phone: String, margin: Double, timezone: String, priority: Int, specialty: String, minimum: Double, description: String, status: ModalityEntryStatus) {
            self.code = code
            self.label = label
            self.region = region
            self.externalRef = externalRef
            self.phone = phone
            self.margin = margin
            self.timezone = timezone
            self.priority = priority
            self.specialty = specialty
            self.minimum = minimum
            self.description = description
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

        func canMoveTo(_ next: ModalityEntryStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == ModalityEntryStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedLoad() -> Double {
            return ((minimum - margin) * 100).rounded() / 100
        }

        func copyValue() -> ModalityEntry {
            return ModalityEntry(
                code: code,
                label: label,
                region: region,
                externalRef: externalRef,
                phone: phone,
                margin: margin,
                timezone: timezone,
                priority: priority,
                specialty: specialty,
                minimum: minimum,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a modality entry in status planned.
    static func newModalityEntry(_ code: String, label: String) -> ModalityEntry {
        return ModalityEntry(
            code: code,
            label: label,
            region: "",
            externalRef: "",
            phone: "",
            margin: 0.0,
            timezone: "",
            priority: 0,
            specialty: "",
            minimum: 0.0,
            description: "",
            status: ModalityEntryStatus.planned
        )
    }
}
