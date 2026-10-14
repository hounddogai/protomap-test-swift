import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a formulary notice is in its life cycle.
    enum FormularyNoticeStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a formulary notice and its current status.
    final class FormularyNotice {
        var code: String
        var label: String
        var endsAt: Int
        var facility: String
        var title: String
        var startsAt: Int
        var copay: Double
        var graceDays: Int
        var name: String
        var attempts: Int
        var status: FormularyNoticeStatus

        init(code: String, label: String, endsAt: Int, facility: String, title: String, startsAt: Int, copay: Double, graceDays: Int, name: String, attempts: Int, status: FormularyNoticeStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.facility = facility
            self.title = title
            self.startsAt = startsAt
            self.copay = copay
            self.graceDays = graceDays
            self.name = name
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

        func canMoveTo(_ next: FormularyNoticeStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == FormularyNoticeStatus.retired
            case .published:
                return next == FormularyNoticeStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FormularyNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("formulary notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedLoad() -> Double {
            return ((copay + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> FormularyNotice {
            return FormularyNotice(
                code: code,
                label: label,
                endsAt: endsAt,
                facility: facility,
                title: title,
                startsAt: startsAt,
                copay: copay,
                graceDays: graceDays,
                name: name,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a formulary notice in status created.
    static func newFormularyNotice(_ code: String, label: String) -> FormularyNotice {
        return FormularyNotice(
            code: code,
            label: label,
            endsAt: 0,
            facility: "",
            title: "",
            startsAt: 0,
            copay: 0.0,
            graceDays: 0,
            name: "",
            attempts: 0,
            status: FormularyNoticeStatus.created
        )
    }
}
