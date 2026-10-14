import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan threshold is in its life cycle.
    enum DischargePlanThresholdStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A discharge plan threshold as the discharge plan team keeps it.
    final class DischargePlanThreshold {
        var code: String
        var name: String
        var startsAt: Int
        var archived: Bool
        var specialty: String
        var cost: Double
        var source: String
        var status: DischargePlanThresholdStatus

        init(code: String, name: String, startsAt: Int, archived: Bool, specialty: String, cost: Double, source: String, status: DischargePlanThresholdStatus) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.archived = archived
            self.specialty = specialty
            self.cost = cost
            self.source = source
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DischargePlanThresholdStatus) -> Bool {
            switch status {
            case .created:
                return next == DischargePlanThresholdStatus.validated || next == DischargePlanThresholdStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DischargePlanThresholdStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DischargePlanThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("discharge plan threshold") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(startsAt) + cost) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanThreshold {
            return DischargePlanThreshold(
                code: code,
                name: name,
                startsAt: startsAt,
                archived: archived,
                specialty: specialty,
                cost: cost,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a discharge plan threshold in status created.
    static func newDischargePlanThreshold(_ code: String, name: String) -> DischargePlanThreshold {
        return DischargePlanThreshold(
            code: code,
            name: name,
            startsAt: 0,
            archived: false,
            specialty: "",
            cost: 0.0,
            source: "",
            status: DischargePlanThresholdStatus.created
        )
    }
}
