import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict bed board forecast is in its life cycle.
    enum StrictBedBoardForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A strict bed board forecast. Its code is unique within a tenant.
    final class StrictBedBoardForecast {
        var code: String
        var label: String
        var title: String
        var capacity: Int
        var revision: Int
        var patientRef: String
        var amount: Double
        var ceiling: Double
        var procedureCode: String
        var attempts: Int
        var expiresAt: Int
        var status: StrictBedBoardForecastStatus

        init(code: String, label: String, title: String, capacity: Int, revision: Int, patientRef: String, amount: Double, ceiling: Double, procedureCode: String, attempts: Int, expiresAt: Int, status: StrictBedBoardForecastStatus) {
            self.code = code
            self.label = label
            self.title = title
            self.capacity = capacity
            self.revision = revision
            self.patientRef = patientRef
            self.amount = amount
            self.ceiling = ceiling
            self.procedureCode = procedureCode
            self.attempts = attempts
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: StrictBedBoardForecastStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == StrictBedBoardForecastStatus.rejected
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: StrictBedBoardForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict bed board forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedExposure() -> Double {
            return ((Double(revision) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> StrictBedBoardForecast {
            return StrictBedBoardForecast(
                code: code,
                label: label,
                title: title,
                capacity: capacity,
                revision: revision,
                patientRef: patientRef,
                amount: amount,
                ceiling: ceiling,
                procedureCode: procedureCode,
                attempts: attempts,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a strict bed board forecast in status proposed.
    static func newStrictBedBoardForecast(_ code: String, label: String) -> StrictBedBoardForecast {
        return StrictBedBoardForecast(
            code: code,
            label: label,
            title: "",
            capacity: 0,
            revision: 0,
            patientRef: "",
            amount: 0.0,
            ceiling: 0.0,
            procedureCode: "",
            attempts: 0,
            expiresAt: 0,
            status: StrictBedBoardForecastStatus.proposed
        )
    }
}
