import AcmePlatform
import Foundation

extension Labs {
    /// Where a seasonal panel score is in its life cycle.
    enum SeasonalPanelScoreStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One seasonal panel score, with what the planners need to act on it.
    final class SeasonalPanelScore {
        var code: String
        var name: String
        var createdAt: Int
        var patientRef: String
        var checksum: String
        var allergy: String
        var priority: Int
        var acuity: Int
        var category: String
        var status: SeasonalPanelScoreStatus

        init(code: String, name: String, createdAt: Int, patientRef: String, checksum: String, allergy: String, priority: Int, acuity: Int, category: String, status: SeasonalPanelScoreStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.patientRef = patientRef
            self.checksum = checksum
            self.allergy = allergy
            self.priority = priority
            self.acuity = acuity
            self.category = category
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

        func canMoveTo(_ next: SeasonalPanelScoreStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == SeasonalPanelScoreStatus.failed
            case .done:
                return next == SeasonalPanelScoreStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalPanelScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal panel score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("seasonal panel score") \(code)"
        }

        func netValue() -> Double {
            return (Double(createdAt) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalPanelScore {
            return SeasonalPanelScore(
                code: code,
                name: name,
                createdAt: createdAt,
                patientRef: patientRef,
                checksum: checksum,
                allergy: allergy,
                priority: priority,
                acuity: acuity,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a seasonal panel score in status new.
    static func newSeasonalPanelScore(_ code: String, name: String) -> SeasonalPanelScore {
        return SeasonalPanelScore(
            code: code,
            name: name,
            createdAt: 0,
            patientRef: "",
            checksum: "",
            allergy: "",
            priority: 0,
            acuity: 0,
            category: "",
            status: SeasonalPanelScoreStatus.new
        )
    }
}
