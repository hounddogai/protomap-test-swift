import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a regional substitution review is in its life cycle.
    enum RegionalSubstitutionReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// The record of a regional substitution review and its current status.
    final class RegionalSubstitutionReview {
        var code: String
        var name: String
        var country: String
        var floorValue: Double
        var patientRef: String
        var score: Double
        var payer: String
        var rate: Double
        var capacity: Int
        var status: RegionalSubstitutionReviewStatus

        init(code: String, name: String, country: String, floorValue: Double, patientRef: String, score: Double, payer: String, rate: Double, capacity: Int, status: RegionalSubstitutionReviewStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.floorValue = floorValue
            self.patientRef = patientRef
            self.score = score
            self.payer = payer
            self.rate = rate
            self.capacity = capacity
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

        func canMoveTo(_ next: RegionalSubstitutionReviewStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalSubstitutionReviewStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RegionalSubstitutionReviewStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalSubstitutionReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional substitution review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("regional substitution review") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((Double(capacity) + score) * 100).rounded() / 100
        }

        func copyValue() -> RegionalSubstitutionReview {
            return RegionalSubstitutionReview(
                code: code,
                name: name,
                country: country,
                floorValue: floorValue,
                patientRef: patientRef,
                score: score,
                payer: payer,
                rate: rate,
                capacity: capacity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional substitution review in status draft.
    static func newRegionalSubstitutionReview(_ code: String, name: String) -> RegionalSubstitutionReview {
        return RegionalSubstitutionReview(
            code: code,
            name: name,
            country: "",
            floorValue: 0.0,
            patientRef: "",
            score: 0.0,
            payer: "",
            rate: 0.0,
            capacity: 0,
            status: RegionalSubstitutionReviewStatus.draft
        )
    }
}
