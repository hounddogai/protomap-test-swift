import AcmePlatform
import Foundation

extension Staffing {
    /// Where a seasonal credential variance is in its life cycle.
    enum SeasonalCredentialVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a seasonal credential variance and its current status.
    final class SeasonalCredentialVariance {
        var code: String
        var label: String
        var version: Int
        var discount: Double
        var limit: Int
        var batchSize: Int
        var amount: Double
        var floorValue: Double
        var status: SeasonalCredentialVarianceStatus

        init(code: String, label: String, version: Int, discount: Double, limit: Int, batchSize: Int, amount: Double, floorValue: Double, status: SeasonalCredentialVarianceStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.discount = discount
            self.limit = limit
            self.batchSize = batchSize
            self.amount = amount
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SeasonalCredentialVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == SeasonalCredentialVarianceStatus.inReview || next == SeasonalCredentialVarianceStatus.reopened
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == SeasonalCredentialVarianceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalCredentialVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal credential variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func adjustedExposure() -> Double {
            return ((floorValue - Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalCredentialVariance {
            return SeasonalCredentialVariance(
                code: code,
                label: label,
                version: version,
                discount: discount,
                limit: limit,
                batchSize: batchSize,
                amount: amount,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal credential variance in status open.
    static func newSeasonalCredentialVariance(_ code: String, label: String) -> SeasonalCredentialVariance {
        return SeasonalCredentialVariance(
            code: code,
            label: label,
            version: 0,
            discount: 0.0,
            limit: 0,
            batchSize: 0,
            amount: 0.0,
            floorValue: 0.0,
            status: SeasonalCredentialVarianceStatus.`open`
        )
    }
}
