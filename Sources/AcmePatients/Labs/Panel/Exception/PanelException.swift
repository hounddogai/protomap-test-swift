import AcmePlatform
import Foundation

extension Labs {
    /// Where a panel exception is in its life cycle.
    enum PanelExceptionStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One panel exception, with what the planners need to act on it.
    final class PanelException {
        var code: String
        var name: String
        var locale: String
        var attributes: [String: String]
        var notes: String
        var startsAt: Int
        var diagnosisCode: String
        var maximum: Double
        var status: PanelExceptionStatus

        init(code: String, name: String, locale: String, attributes: [String: String], notes: String, startsAt: Int, diagnosisCode: String, maximum: Double, status: PanelExceptionStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.attributes = attributes
            self.notes = notes
            self.startsAt = startsAt
            self.diagnosisCode = diagnosisCode
            self.maximum = maximum
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: PanelExceptionStatus) -> Bool {
            switch status {
            case .draft:
                return next == PanelExceptionStatus.active || next == PanelExceptionStatus.suspended
            case .pending:
                return next == PanelExceptionStatus.active
            case .active:
                return next == PanelExceptionStatus.closed
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: PanelExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("panel exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
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

        func effectiveExposure() -> Double {
            return ((Double(startsAt) - maximum) * 100).rounded() / 100
        }

        func copyValue() -> PanelException {
            return PanelException(
                code: code,
                name: name,
                locale: locale,
                attributes: attributes,
                notes: notes,
                startsAt: startsAt,
                diagnosisCode: diagnosisCode,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a panel exception in status draft.
    static func newPanelException(_ code: String, name: String) -> PanelException {
        return PanelException(
            code: code,
            name: name,
            locale: "",
            attributes: [:],
            notes: "",
            startsAt: 0,
            diagnosisCode: "",
            maximum: 0.0,
            status: PanelExceptionStatus.draft
        )
    }
}
