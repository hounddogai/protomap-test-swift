import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a rounding threshold is in its life cycle.
    enum RoundingThresholdStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One rounding threshold, with what the planners need to act on it.
    final class RoundingThreshold {
        var code: String
        var name: String
        var rate: Double
        var ratio: Double
        var archived: Bool
        var visible: Bool
        var startsAt: Int
        var encounterID: String
        var active: Bool
        var category: String
        var status: RoundingThresholdStatus

        init(code: String, name: String, rate: Double, ratio: Double, archived: Bool, visible: Bool, startsAt: Int, encounterID: String, active: Bool, category: String, status: RoundingThresholdStatus) {
            self.code = code
            self.name = name
            self.rate = rate
            self.ratio = ratio
            self.archived = archived
            self.visible = visible
            self.startsAt = startsAt
            self.encounterID = encounterID
            self.active = active
            self.category = category
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

        func canMoveTo(_ next: RoundingThresholdStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .suspended, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
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

        func moveTo(_ next: RoundingThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rounding threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netLoad() -> Double {
            return ((ratio + Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RoundingThreshold {
            return RoundingThreshold(
                code: code,
                name: name,
                rate: rate,
                ratio: ratio,
                archived: archived,
                visible: visible,
                startsAt: startsAt,
                encounterID: encounterID,
                active: active,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a rounding threshold in status draft.
    static func newRoundingThreshold(_ code: String, name: String) -> RoundingThreshold {
        return RoundingThreshold(
            code: code,
            name: name,
            rate: 0.0,
            ratio: 0.0,
            archived: false,
            visible: false,
            startsAt: 0,
            encounterID: "",
            active: false,
            category: "",
            status: RoundingThresholdStatus.draft
        )
    }
}
