import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a seasonal charge score is in its life cycle.
    enum SeasonalChargeScoreStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal charge score. Its code is unique within a tenant.
    final class SeasonalChargeScore {
        var code: String
        var name: String
        var category: String
        var currency: String
        var score: Double
        var limit: Int
        var graceDays: Int
        var tags: [String]
        var visitMinutes: Int
        var diagnosisCode: String
        var status: SeasonalChargeScoreStatus

        init(code: String, name: String, category: String, currency: String, score: Double, limit: Int, graceDays: Int, tags: [String], visitMinutes: Int, diagnosisCode: String, status: SeasonalChargeScoreStatus) {
            self.code = code
            self.name = name
            self.category = category
            self.currency = currency
            self.score = score
            self.limit = limit
            self.graceDays = graceDays
            self.tags = tags
            self.visitMinutes = visitMinutes
            self.diagnosisCode = diagnosisCode
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

        func canMoveTo(_ next: SeasonalChargeScoreStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == SeasonalChargeScoreStatus.draining
            case .draining:
                return next == SeasonalChargeScoreStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalChargeScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal charge score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return (Double(graceDays) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalChargeScore {
            return SeasonalChargeScore(
                code: code,
                name: name,
                category: category,
                currency: currency,
                score: score,
                limit: limit,
                graceDays: graceDays,
                tags: tags,
                visitMinutes: visitMinutes,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal charge score in status idle.
    static func newSeasonalChargeScore(_ code: String, name: String) -> SeasonalChargeScore {
        return SeasonalChargeScore(
            code: code,
            name: name,
            category: "",
            currency: "",
            score: 0.0,
            limit: 0,
            graceDays: 0,
            tags: [],
            visitMinutes: 0,
            diagnosisCode: "",
            status: SeasonalChargeScoreStatus.idle
        )
    }
}
