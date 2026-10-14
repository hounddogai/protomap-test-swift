import AcmePlatform
import Foundation

extension Referrals {
    /// Where a closure window is in its life cycle.
    enum ClosureWindowStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One closure window, with what the planners need to act on it.
    final class ClosureWindow {
        var code: String
        var label: String
        var rate: Double
        var diagnosisCode: String
        var endsAt: Int
        var summary: String
        var refills: Int
        var minimum: Double
        var allergy: String
        var locale: String
        var title: String
        var status: ClosureWindowStatus

        init(code: String, label: String, rate: Double, diagnosisCode: String, endsAt: Int, summary: String, refills: Int, minimum: Double, allergy: String, locale: String, title: String, status: ClosureWindowStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.diagnosisCode = diagnosisCode
            self.endsAt = endsAt
            self.summary = summary
            self.refills = refills
            self.minimum = minimum
            self.allergy = allergy
            self.locale = locale
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

        func canMoveTo(_ next: ClosureWindowStatus) -> Bool {
            switch status {
            case .created:
                return next == ClosureWindowStatus.retired
            case .validated:
                return next == ClosureWindowStatus.published || next == ClosureWindowStatus.retired
            case .published:
                return next == ClosureWindowStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ClosureWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("closure window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("closure window") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(endsAt) * minimum * 100).rounded() / 100
        }

        func copyValue() -> ClosureWindow {
            return ClosureWindow(
                code: code,
                label: label,
                rate: rate,
                diagnosisCode: diagnosisCode,
                endsAt: endsAt,
                summary: summary,
                refills: refills,
                minimum: minimum,
                allergy: allergy,
                locale: locale,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a closure window in status created.
    static func newClosureWindow(_ code: String, label: String) -> ClosureWindow {
        return ClosureWindow(
            code: code,
            label: label,
            rate: 0.0,
            diagnosisCode: "",
            endsAt: 0,
            summary: "",
            refills: 0,
            minimum: 0.0,
            allergy: "",
            locale: "",
            title: "",
            status: ClosureWindowStatus.created
        )
    }
}
