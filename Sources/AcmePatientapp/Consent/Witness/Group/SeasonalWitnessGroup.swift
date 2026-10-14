import AcmePlatform
import Foundation

extension Consent {
    /// Where a seasonal witness group is in its life cycle.
    enum SeasonalWitnessGroupStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A seasonal witness group as the witness team keeps it.
    final class SeasonalWitnessGroup {
        var code: String
        var name: String
        var startsAt: Int
        var allergy: String
        var priority: Int
        var dosageMg: Double
        var floorValue: Double
        var phone: String
        var encounterID: String
        var region: String
        var status: SeasonalWitnessGroupStatus

        init(code: String, name: String, startsAt: Int, allergy: String, priority: Int, dosageMg: Double, floorValue: Double, phone: String, encounterID: String, region: String, status: SeasonalWitnessGroupStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.allergy = allergy
            self.priority = priority
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.phone = phone
            self.encounterID = encounterID
            self.region = region
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

        func canMoveTo(_ next: SeasonalWitnessGroupStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == SeasonalWitnessGroupStatus.suspended || next == SeasonalWitnessGroupStatus.closed
            case .active:
                return next == SeasonalWitnessGroupStatus.suspended || next == SeasonalWitnessGroupStatus.closed
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

        func moveTo(_ next: SeasonalWitnessGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal witness group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func netValue() -> Double {
            return ((Double(startsAt) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalWitnessGroup {
            return SeasonalWitnessGroup(
                code: code,
                name: name,
                startsAt: startsAt,
                allergy: allergy,
                priority: priority,
                dosageMg: dosageMg,
                floorValue: floorValue,
                phone: phone,
                encounterID: encounterID,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a seasonal witness group in status draft.
    static func newSeasonalWitnessGroup(_ code: String, name: String) -> SeasonalWitnessGroup {
        return SeasonalWitnessGroup(
            code: code,
            name: name,
            startsAt: 0,
            allergy: "",
            priority: 0,
            dosageMg: 0.0,
            floorValue: 0.0,
            phone: "",
            encounterID: "",
            region: "",
            status: SeasonalWitnessGroupStatus.draft
        )
    }
}
