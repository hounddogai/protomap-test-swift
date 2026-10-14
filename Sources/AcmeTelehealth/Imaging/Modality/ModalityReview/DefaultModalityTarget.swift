import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default modality target is in its life cycle.
    enum DefaultModalityTargetStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default modality target. Its code is unique within a tenant.
    final class DefaultModalityTarget {
        var code: String
        var title: String
        var label: String
        var visible: Bool
        var updatedAt: Int
        var facility: String
        var ownerID: String
        var contactEmail: String
        var sequence: Int
        var margin: Double
        var createdAt: Int
        var status: DefaultModalityTargetStatus

        init(code: String, title: String, label: String, visible: Bool, updatedAt: Int, facility: String, ownerID: String, contactEmail: String, sequence: Int, margin: Double, createdAt: Int, status: DefaultModalityTargetStatus) {
            self.code = code
            self.title = title
            self.label = label
            self.visible = visible
            self.updatedAt = updatedAt
            self.facility = facility
            self.ownerID = ownerID
            self.contactEmail = contactEmail
            self.sequence = sequence
            self.margin = margin
            self.createdAt = createdAt
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

        func canMoveTo(_ next: DefaultModalityTargetStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultModalityTargetStatus.completed
            case .inProgress:
                return next == DefaultModalityTargetStatus.completed
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

        func moveTo(_ next: DefaultModalityTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default modality target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func adjustedLoad() -> Double {
            return (margin * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> DefaultModalityTarget {
            return DefaultModalityTarget(
                code: code,
                title: title,
                label: label,
                visible: visible,
                updatedAt: updatedAt,
                facility: facility,
                ownerID: ownerID,
                contactEmail: contactEmail,
                sequence: sequence,
                margin: margin,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a default modality target in status planned.
    static func newDefaultModalityTarget(_ code: String, title: String) -> DefaultModalityTarget {
        return DefaultModalityTarget(
            code: code,
            title: title,
            label: "",
            visible: false,
            updatedAt: 0,
            facility: "",
            ownerID: "",
            contactEmail: "",
            sequence: 0,
            margin: 0.0,
            createdAt: 0,
            status: DefaultModalityTargetStatus.planned
        )
    }
}
