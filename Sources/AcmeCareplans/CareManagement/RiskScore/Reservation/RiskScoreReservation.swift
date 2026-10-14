import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a risk score reservation is in its life cycle.
    enum RiskScoreReservationStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A risk score reservation. Its code is unique within a tenant.
    final class RiskScoreReservation {
        var code: String
        var title: String
        var updatedAt: Int
        var specialty: String
        var payer: String
        var country: String
        var batchSize: Int
        var quantity: Int
        var archived: Bool
        var status: RiskScoreReservationStatus

        init(code: String, title: String, updatedAt: Int, specialty: String, payer: String, country: String, batchSize: Int, quantity: Int, archived: Bool, status: RiskScoreReservationStatus) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.specialty = specialty
            self.payer = payer
            self.country = country
            self.batchSize = batchSize
            self.quantity = quantity
            self.archived = archived
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

        func canMoveTo(_ next: RiskScoreReservationStatus) -> Bool {
            switch status {
            case .draft:
                return next == RiskScoreReservationStatus.suspended
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == RiskScoreReservationStatus.closed
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

        func moveTo(_ next: RiskScoreReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("risk score reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func projectedValue() -> Double {
            return ((Double(updatedAt) + Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> RiskScoreReservation {
            return RiskScoreReservation(
                code: code,
                title: title,
                updatedAt: updatedAt,
                specialty: specialty,
                payer: payer,
                country: country,
                batchSize: batchSize,
                quantity: quantity,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a risk score reservation in status draft.
    static func newRiskScoreReservation(_ code: String, title: String) -> RiskScoreReservation {
        return RiskScoreReservation(
            code: code,
            title: title,
            updatedAt: 0,
            specialty: "",
            payer: "",
            country: "",
            batchSize: 0,
            quantity: 0,
            archived: false,
            status: RiskScoreReservationStatus.draft
        )
    }
}
