import AcmePlatform
import Foundation

extension Imaging {
    /// Where a weighted study quota is in its life cycle.
    enum WeightedStudyQuotaStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One weighted study quota, with what the planners need to act on it.
    final class WeightedStudyQuota {
        var code: String
        var title: String
        var discount: Double
        var source: String
        var quantity: Int
        var clinicianID: String
        var ratio: Double
        var score: Double
        var diagnosisCode: String
        var category: String
        var expiresAt: Int
        var status: WeightedStudyQuotaStatus

        init(code: String, title: String, discount: Double, source: String, quantity: Int, clinicianID: String, ratio: Double, score: Double, diagnosisCode: String, category: String, expiresAt: Int, status: WeightedStudyQuotaStatus) {
            self.code = code
            self.title = title
            self.discount = discount
            self.source = source
            self.quantity = quantity
            self.clinicianID = clinicianID
            self.ratio = ratio
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.category = category
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedStudyQuotaStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == WeightedStudyQuotaStatus.draining
            case .draining:
                return next == WeightedStudyQuotaStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedStudyQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted study quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func netValue() -> Double {
            return (score * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedStudyQuota {
            return WeightedStudyQuota(
                code: code,
                title: title,
                discount: discount,
                source: source,
                quantity: quantity,
                clinicianID: clinicianID,
                ratio: ratio,
                score: score,
                diagnosisCode: diagnosisCode,
                category: category,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a weighted study quota in status idle.
    static func newWeightedStudyQuota(_ code: String, title: String) -> WeightedStudyQuota {
        return WeightedStudyQuota(
            code: code,
            title: title,
            discount: 0.0,
            source: "",
            quantity: 0,
            clinicianID: "",
            ratio: 0.0,
            score: 0.0,
            diagnosisCode: "",
            category: "",
            expiresAt: 0,
            status: WeightedStudyQuotaStatus.idle
        )
    }
}
