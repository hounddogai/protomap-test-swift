import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality window is in its life cycle.
    enum ModalityWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a modality window and its current status.
    final class ModalityWindow {
        var code: String
        var label: String
        var tags: [String]
        var description: String
        var version: Int
        var clinicianID: String
        var quantity: Int
        var attempts: Int
        var status: ModalityWindowStatus

        init(code: String, label: String, tags: [String], description: String, version: Int, clinicianID: String, quantity: Int, attempts: Int, status: ModalityWindowStatus) {
            self.code = code
            self.label = label
            self.tags = tags
            self.description = description
            self.version = version
            self.clinicianID = clinicianID
            self.quantity = quantity
            self.attempts = attempts
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

        func canMoveTo(_ next: ModalityWindowStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == ModalityWindowStatus.published || next == ModalityWindowStatus.retired
            case .published:
                return next == ModalityWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ModalityWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("modality window") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedTotal() -> Double {
            return ((Double(attempts) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ModalityWindow {
            return ModalityWindow(
                code: code,
                label: label,
                tags: tags,
                description: description,
                version: version,
                clinicianID: clinicianID,
                quantity: quantity,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a modality window in status created.
    static func newModalityWindow(_ code: String, label: String) -> ModalityWindow {
        return ModalityWindow(
            code: code,
            label: label,
            tags: [],
            description: "",
            version: 0,
            clinicianID: "",
            quantity: 0,
            attempts: 0,
            status: ModalityWindowStatus.created
        )
    }
}
