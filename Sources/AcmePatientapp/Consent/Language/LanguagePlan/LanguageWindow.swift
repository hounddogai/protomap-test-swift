import AcmePlatform
import Foundation

extension Consent {
    /// Where a language window is in its life cycle.
    enum LanguageWindowStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A language window as the language team keeps it.
    final class LanguageWindow {
        var code: String
        var label: String
        var encounterID: String
        var ratio: Double
        var limit: Int
        var rate: Double
        var patientRef: String
        var name: String
        var dosageMg: Double
        var status: LanguageWindowStatus

        init(code: String, label: String, encounterID: String, ratio: Double, limit: Int, rate: Double, patientRef: String, name: String, dosageMg: Double, status: LanguageWindowStatus) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.ratio = ratio
            self.limit = limit
            self.rate = rate
            self.patientRef = patientRef
            self.name = name
            self.dosageMg = dosageMg
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LanguageWindowStatus) -> Bool {
            switch status {
            case .proposed:
                return next == LanguageWindowStatus.withdrawn
            case .approved:
                return next == LanguageWindowStatus.withdrawn
            case .rejected:
                return next == LanguageWindowStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("language window") \(code)"
        }

        func netTotal() -> Double {
            return ((rate + dosageMg) * 100).rounded() / 100
        }

        func copyValue() -> LanguageWindow {
            return LanguageWindow(
                code: code,
                label: label,
                encounterID: encounterID,
                ratio: ratio,
                limit: limit,
                rate: rate,
                patientRef: patientRef,
                name: name,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a language window in status proposed.
    static func newLanguageWindow(_ code: String, label: String) -> LanguageWindow {
        return LanguageWindow(
            code: code,
            label: label,
            encounterID: "",
            ratio: 0.0,
            limit: 0,
            rate: 0.0,
            patientRef: "",
            name: "",
            dosageMg: 0.0,
            status: LanguageWindowStatus.proposed
        )
    }
}
