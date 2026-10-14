import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary digest is in its life cycle.
    enum FormularyDigestStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One formulary digest, with what the planners need to act on it.
    final class FormularyDigest {
        var code: String
        var label: String
        var approved: Bool
        var segment: String
        var ceiling: Double
        var notes: String
        var visitMinutes: Int
        var facility: String
        var timezone: String
        var allergy: String
        var title: String
        var status: FormularyDigestStatus

        init(code: String, label: String, approved: Bool, segment: String, ceiling: Double, notes: String, visitMinutes: Int, facility: String, timezone: String, allergy: String, title: String, status: FormularyDigestStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.segment = segment
            self.ceiling = ceiling
            self.notes = notes
            self.visitMinutes = visitMinutes
            self.facility = facility
            self.timezone = timezone
            self.allergy = allergy
            self.title = title
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

        func canMoveTo(_ next: FormularyDigestStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
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
                return next == FormularyDigestStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedVolume() -> Double {
            return ((Double(visitMinutes) - ceiling) * 100).rounded() / 100
        }

        func copyValue() -> FormularyDigest {
            return FormularyDigest(
                code: code,
                label: label,
                approved: approved,
                segment: segment,
                ceiling: ceiling,
                notes: notes,
                visitMinutes: visitMinutes,
                facility: facility,
                timezone: timezone,
                allergy: allergy,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a formulary digest in status created.
    static func newFormularyDigest(_ code: String, label: String) -> FormularyDigest {
        return FormularyDigest(
            code: code,
            label: label,
            approved: false,
            segment: "",
            ceiling: 0.0,
            notes: "",
            visitMinutes: 0,
            facility: "",
            timezone: "",
            allergy: "",
            title: "",
            status: FormularyDigestStatus.created
        )
    }
}
