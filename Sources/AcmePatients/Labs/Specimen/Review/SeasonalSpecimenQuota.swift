import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal specimen quota is in its life cycle.
    enum SeasonalSpecimenQuotaStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal specimen quota, with what the planners need to act on it.
    final class SeasonalSpecimenQuota {
        var code: String
        var label: String
        var limit: Int
        var visible: Bool
        var visitMinutes: Int
        var revision: Int
        var score: Double
        var status: SeasonalSpecimenQuotaStatus

        init(code: String, label: String, limit: Int, visible: Bool, visitMinutes: Int, revision: Int, score: Double, status: SeasonalSpecimenQuotaStatus) {
            self.code = code
            self.label = label
            self.limit = limit
            self.visible = visible
            self.visitMinutes = visitMinutes
            self.revision = revision
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: SeasonalSpecimenQuotaStatus) -> Bool {
            switch status {
            case .new:
                return next == SeasonalSpecimenQuotaStatus.queued
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == SeasonalSpecimenQuotaStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalSpecimenQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal specimen quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\("seasonal specimen quota") \(code)"
        }

        func projectedTotal() -> Double {
            return (Double(revision) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSpecimenQuota {
            return SeasonalSpecimenQuota(
                code: code,
                label: label,
                limit: limit,
                visible: visible,
                visitMinutes: visitMinutes,
                revision: revision,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal specimen quota in status new.
    static func newSeasonalSpecimenQuota(_ code: String, label: String) -> SeasonalSpecimenQuota {
        return SeasonalSpecimenQuota(
            code: code,
            label: label,
            limit: 0,
            visible: false,
            visitMinutes: 0,
            revision: 0,
            score: 0.0,
            status: SeasonalSpecimenQuotaStatus.new
        )
    }
}
