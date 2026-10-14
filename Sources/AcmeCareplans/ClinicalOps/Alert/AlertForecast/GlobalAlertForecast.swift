import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a global alert forecast is in its life cycle.
    enum GlobalAlertForecastStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a global alert forecast and its current status.
    final class GlobalAlertForecast {
        var code: String
        var label: String
        var specialty: String
        var externalRef: String
        var ownerID: String
        var quantity: Int
        var status: GlobalAlertForecastStatus

        init(code: String, label: String, specialty: String, externalRef: String, ownerID: String, quantity: Int, status: GlobalAlertForecastStatus) {
            self.code = code
            self.label = label
            self.specialty = specialty
            self.externalRef = externalRef
            self.ownerID = ownerID
            self.quantity = quantity
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

        func canMoveTo(_ next: GlobalAlertForecastStatus) -> Bool {
            switch status {
            case .created:
                return next == GlobalAlertForecastStatus.validated || next == GlobalAlertForecastStatus.published
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: GlobalAlertForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global alert forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> GlobalAlertForecast {
            return GlobalAlertForecast(
                code: code,
                label: label,
                specialty: specialty,
                externalRef: externalRef,
                ownerID: ownerID,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a global alert forecast in status created.
    static func newGlobalAlertForecast(_ code: String, label: String) -> GlobalAlertForecast {
        return GlobalAlertForecast(
            code: code,
            label: label,
            specialty: "",
            externalRef: "",
            ownerID: "",
            quantity: 0,
            status: GlobalAlertForecastStatus.created
        )
    }
}
