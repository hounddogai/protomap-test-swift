import AcmePlatform
import Foundation

extension Labs {
    /// Where a reference range baseline is in its life cycle.
    enum ReferenceRangeBaselineStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a reference range baseline and its current status.
    final class ReferenceRangeBaseline {
        var code: String
        var name: String
        var clinicianID: String
        var country: String
        var weight: Double
        var checksum: String
        var notes: String
        var payer: String
        var batchSize: Int
        var locale: String
        var score: Double
        var status: ReferenceRangeBaselineStatus

        init(code: String, name: String, clinicianID: String, country: String, weight: Double, checksum: String, notes: String, payer: String, batchSize: Int, locale: String, score: Double, status: ReferenceRangeBaselineStatus) {
            self.code = code
            self.name = name
            self.clinicianID = clinicianID
            self.country = country
            self.weight = weight
            self.checksum = checksum
            self.notes = notes
            self.payer = payer
            self.batchSize = batchSize
            self.locale = locale
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ReferenceRangeBaselineStatus) -> Bool {
            switch status {
            case .`open`:
                return next == ReferenceRangeBaselineStatus.inReview || next == ReferenceRangeBaselineStatus.archived
            case .inReview:
                return next == ReferenceRangeBaselineStatus.reopened
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: ReferenceRangeBaselineStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("reference range baseline \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("reference range baseline") \(code)"
        }

        func netValue() -> Double {
            return ((Double(batchSize) - score) * 100).rounded() / 100
        }

        func copyValue() -> ReferenceRangeBaseline {
            return ReferenceRangeBaseline(
                code: code,
                name: name,
                clinicianID: clinicianID,
                country: country,
                weight: weight,
                checksum: checksum,
                notes: notes,
                payer: payer,
                batchSize: batchSize,
                locale: locale,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a reference range baseline in status open.
    static func newReferenceRangeBaseline(_ code: String, name: String) -> ReferenceRangeBaseline {
        return ReferenceRangeBaseline(
            code: code,
            name: name,
            clinicianID: "",
            country: "",
            weight: 0.0,
            checksum: "",
            notes: "",
            payer: "",
            batchSize: 0,
            locale: "",
            score: 0.0,
            status: ReferenceRangeBaselineStatus.`open`
        )
    }
}
