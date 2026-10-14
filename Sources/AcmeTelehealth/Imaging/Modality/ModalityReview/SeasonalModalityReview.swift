import AcmePlatform
import Foundation

extension Imaging {
    /// Where a seasonal modality review is in its life cycle.
    enum SeasonalModalityReviewStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A seasonal modality review. Its code is unique within a tenant.
    final class SeasonalModalityReview {
        var code: String
        var name: String
        var weight: Double
        var endsAt: Int
        var batchSize: Int
        var visible: Bool
        var contactEmail: String
        var createdAt: Int
        var description: String
        var status: SeasonalModalityReviewStatus

        init(code: String, name: String, weight: Double, endsAt: Int, batchSize: Int, visible: Bool, contactEmail: String, createdAt: Int, description: String, status: SeasonalModalityReviewStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.visible = visible
            self.contactEmail = contactEmail
            self.createdAt = createdAt
            self.description = description
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

        func canMoveTo(_ next: SeasonalModalityReviewStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SeasonalModalityReviewStatus.reopened || next == SeasonalModalityReviewStatus.archived
            case .inReview:
                return next == SeasonalModalityReviewStatus.reopened || next == SeasonalModalityReviewStatus.archived
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

        func moveTo(_ next: SeasonalModalityReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal modality review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal modality review") \(code)"
        }

        func adjustedLoad() -> Double {
            return (Double(createdAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> SeasonalModalityReview {
            return SeasonalModalityReview(
                code: code,
                name: name,
                weight: weight,
                endsAt: endsAt,
                batchSize: batchSize,
                visible: visible,
                contactEmail: contactEmail,
                createdAt: createdAt,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a seasonal modality review in status open.
    static func newSeasonalModalityReview(_ code: String, name: String) -> SeasonalModalityReview {
        return SeasonalModalityReview(
            code: code,
            name: name,
            weight: 0.0,
            endsAt: 0,
            batchSize: 0,
            visible: false,
            contactEmail: "",
            createdAt: 0,
            description: "",
            status: SeasonalModalityReviewStatus.`open`
        )
    }
}
