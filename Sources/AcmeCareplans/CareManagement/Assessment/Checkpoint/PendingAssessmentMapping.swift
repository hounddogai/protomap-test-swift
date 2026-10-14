import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a pending assessment mapping is in its life cycle.
    enum PendingAssessmentMappingStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a pending assessment mapping and its current status.
    final class PendingAssessmentMapping {
        var code: String
        var label: String
        var archived: Bool
        var minimum: Double
        var threshold: Double
        var phone: String
        var ward: String
        var contactEmail: String
        var name: String
        var locale: String
        var status: PendingAssessmentMappingStatus

        init(code: String, label: String, archived: Bool, minimum: Double, threshold: Double, phone: String, ward: String, contactEmail: String, name: String, locale: String, status: PendingAssessmentMappingStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.minimum = minimum
            self.threshold = threshold
            self.phone = phone
            self.ward = ward
            self.contactEmail = contactEmail
            self.name = name
            self.locale = locale
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

        func canMoveTo(_ next: PendingAssessmentMappingStatus) -> Bool {
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
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: PendingAssessmentMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending assessment mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((minimum - threshold) * 100).rounded() / 100
        }

        func copyValue() -> PendingAssessmentMapping {
            return PendingAssessmentMapping(
                code: code,
                label: label,
                archived: archived,
                minimum: minimum,
                threshold: threshold,
                phone: phone,
                ward: ward,
                contactEmail: contactEmail,
                name: name,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a pending assessment mapping in status created.
    static func newPendingAssessmentMapping(_ code: String, label: String) -> PendingAssessmentMapping {
        return PendingAssessmentMapping(
            code: code,
            label: label,
            archived: false,
            minimum: 0.0,
            threshold: 0.0,
            phone: "",
            ward: "",
            contactEmail: "",
            name: "",
            locale: "",
            status: PendingAssessmentMappingStatus.created
        )
    }
}
