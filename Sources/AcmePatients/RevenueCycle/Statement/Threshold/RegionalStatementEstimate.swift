import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a regional statement estimate is in its life cycle.
    enum RegionalStatementEstimateStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional statement estimate as the statement team keeps it.
    final class RegionalStatementEstimate {
        var code: String
        var title: String
        var rate: Double
        var threshold: Double
        var version: Int
        var country: String
        var bed: String
        var limit: Int
        var batchSize: Int
        var expiresAt: Int
        var status: RegionalStatementEstimateStatus

        init(code: String, title: String, rate: Double, threshold: Double, version: Int, country: String, bed: String, limit: Int, batchSize: Int, expiresAt: Int, status: RegionalStatementEstimateStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.threshold = threshold
            self.version = version
            self.country = country
            self.bed = bed
            self.limit = limit
            self.batchSize = batchSize
            self.expiresAt = expiresAt
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

        func canMoveTo(_ next: RegionalStatementEstimateStatus) -> Bool {
            switch status {
            case .draft:
                return next == RegionalStatementEstimateStatus.pending || next == RegionalStatementEstimateStatus.suspended
            case .pending:
                return next == RegionalStatementEstimateStatus.suspended
            case .active:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalStatementEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional statement estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("regional statement estimate") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((Double(version) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalStatementEstimate {
            return RegionalStatementEstimate(
                code: code,
                title: title,
                rate: rate,
                threshold: threshold,
                version: version,
                country: country,
                bed: bed,
                limit: limit,
                batchSize: batchSize,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a regional statement estimate in status draft.
    static func newRegionalStatementEstimate(_ code: String, title: String) -> RegionalStatementEstimate {
        return RegionalStatementEstimate(
            code: code,
            title: title,
            rate: 0.0,
            threshold: 0.0,
            version: 0,
            country: "",
            bed: "",
            limit: 0,
            batchSize: 0,
            expiresAt: 0,
            status: RegionalStatementEstimateStatus.draft
        )
    }
}
