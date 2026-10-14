import AcmePlatform
import Foundation

extension Imaging {
    /// Where a modality score is in its life cycle.
    enum ModalityScoreStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A modality score as the modality team keeps it.
    final class ModalityScore {
        var code: String
        var title: String
        var category: String
        var patientRef: String
        var capacity: Int
        var revision: Int
        var discount: Double
        var attributes: [String: String]
        var sequence: Int
        var status: ModalityScoreStatus

        init(code: String, title: String, category: String, patientRef: String, capacity: Int, revision: Int, discount: Double, attributes: [String: String], sequence: Int, status: ModalityScoreStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.patientRef = patientRef
            self.capacity = capacity
            self.revision = revision
            self.discount = discount
            self.attributes = attributes
            self.sequence = sequence
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

        func canMoveTo(_ next: ModalityScoreStatus) -> Bool {
            switch status {
            case .created:
                return next == ModalityScoreStatus.validated || next == ModalityScoreStatus.retired
            case .validated:
                return next == ModalityScoreStatus.published
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

        func moveTo(_ next: ModalityScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("modality score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\("modality score") \(code)"
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

        func weightedExposure() -> Double {
            return ((Double(sequence) + discount) * 100).rounded() / 100
        }

        func copyValue() -> ModalityScore {
            return ModalityScore(
                code: code,
                title: title,
                category: category,
                patientRef: patientRef,
                capacity: capacity,
                revision: revision,
                discount: discount,
                attributes: attributes,
                sequence: sequence,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a modality score in status created.
    static func newModalityScore(_ code: String, title: String) -> ModalityScore {
        return ModalityScore(
            code: code,
            title: title,
            category: "",
            patientRef: "",
            capacity: 0,
            revision: 0,
            discount: 0.0,
            attributes: [:],
            sequence: 0,
            status: ModalityScoreStatus.created
        )
    }
}
