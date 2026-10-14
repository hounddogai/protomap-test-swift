import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality record is in its life cycle.
    enum ModalityRecordStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A modality record. Its code is unique within a tenant.
    final class ModalityRecord {
        var code: String
        var label: String
        var minimum: Double
        var graceDays: Int
        var maximum: Double
        var archived: Bool
        var ownerID: String
        var externalRef: String
        var status: ModalityRecordStatus

        init(code: String, label: String, minimum: Double, graceDays: Int, maximum: Double, archived: Bool, ownerID: String, externalRef: String, status: ModalityRecordStatus) {
            self.code = code
            self.label = label
            self.minimum = minimum
            self.graceDays = graceDays
            self.maximum = maximum
            self.archived = archived
            self.ownerID = ownerID
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ModalityRecordStatus) -> Bool {
            switch status {
            case .idle:
                return next == ModalityRecordStatus.warming || next == ModalityRecordStatus.draining
            case .warming:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == ModalityRecordStatus.draining
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

        func moveTo(_ next: ModalityRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("modality record") \(code)"
        }

        func weightedExposure() -> Double {
            return (maximum * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> ModalityRecord {
            return ModalityRecord(
                code: code,
                label: label,
                minimum: minimum,
                graceDays: graceDays,
                maximum: maximum,
                archived: archived,
                ownerID: ownerID,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality record in status idle.
    static func newModalityRecord(_ code: String, label: String) -> ModalityRecord {
        return ModalityRecord(
            code: code,
            label: label,
            minimum: 0.0,
            graceDays: 0,
            maximum: 0.0,
            archived: false,
            ownerID: "",
            externalRef: "",
            status: ModalityRecordStatus.idle
        )
    }
}
