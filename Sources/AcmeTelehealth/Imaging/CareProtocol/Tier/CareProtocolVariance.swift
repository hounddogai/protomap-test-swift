import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol variance is in its life cycle.
    enum CareProtocolVarianceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A care protocol variance as the care protocol team keeps it.
    final class CareProtocolVariance {
        var code: String
        var title: String
        var ratio: Double
        var notes: String
        var ceiling: Double
        var currency: String
        var procedureCode: String
        var margin: Double
        var score: Double
        var archived: Bool
        var ward: String
        var status: CareProtocolVarianceStatus

        init(code: String, title: String, ratio: Double, notes: String, ceiling: Double, currency: String, procedureCode: String, margin: Double, score: Double, archived: Bool, ward: String, status: CareProtocolVarianceStatus) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.notes = notes
            self.ceiling = ceiling
            self.currency = currency
            self.procedureCode = procedureCode
            self.margin = margin
            self.score = score
            self.archived = archived
            self.ward = ward
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

        func canMoveTo(_ next: CareProtocolVarianceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == CareProtocolVarianceStatus.rejected
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == CareProtocolVarianceStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func adjustedTotal() -> Double {
            return ((ratio + margin) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolVariance {
            return CareProtocolVariance(
                code: code,
                title: title,
                ratio: ratio,
                notes: notes,
                ceiling: ceiling,
                currency: currency,
                procedureCode: procedureCode,
                margin: margin,
                score: score,
                archived: archived,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a care protocol variance in status proposed.
    static func newCareProtocolVariance(_ code: String, title: String) -> CareProtocolVariance {
        return CareProtocolVariance(
            code: code,
            title: title,
            ratio: 0.0,
            notes: "",
            ceiling: 0.0,
            currency: "",
            procedureCode: "",
            margin: 0.0,
            score: 0.0,
            archived: false,
            ward: "",
            status: CareProtocolVarianceStatus.proposed
        )
    }
}
