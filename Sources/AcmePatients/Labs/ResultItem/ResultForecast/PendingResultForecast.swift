import AcmePlatform
import Foundation

extension Labs {
    /// Where a pending result forecast is in its life cycle.
    enum PendingResultForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A pending result forecast. Its code is unique within a tenant.
    final class PendingResultForecast {
        var code: String
        var label: String
        var notes: String
        var visitMinutes: Int
        var createdAt: Int
        var diagnosisCode: String
        var allergy: String
        var contactEmail: String
        var status: PendingResultForecastStatus

        init(code: String, label: String, notes: String, visitMinutes: Int, createdAt: Int, diagnosisCode: String, allergy: String, contactEmail: String, status: PendingResultForecastStatus) {
            self.code = code
            self.label = label
            self.notes = notes
            self.visitMinutes = visitMinutes
            self.createdAt = createdAt
            self.diagnosisCode = diagnosisCode
            self.allergy = allergy
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: PendingResultForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PendingResultForecastStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PendingResultForecastStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PendingResultForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("pending result forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("pending result forecast") \(code)"
        }

        func adjustedVolume() -> Double {
            return ((Double(visitMinutes) - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PendingResultForecast {
            return PendingResultForecast(
                code: code,
                label: label,
                notes: notes,
                visitMinutes: visitMinutes,
                createdAt: createdAt,
                diagnosisCode: diagnosisCode,
                allergy: allergy,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a pending result forecast in status proposed.
    static func newPendingResultForecast(_ code: String, label: String) -> PendingResultForecast {
        return PendingResultForecast(
            code: code,
            label: label,
            notes: "",
            visitMinutes: 0,
            createdAt: 0,
            diagnosisCode: "",
            allergy: "",
            contactEmail: "",
            status: PendingResultForecastStatus.proposed
        )
    }
}
