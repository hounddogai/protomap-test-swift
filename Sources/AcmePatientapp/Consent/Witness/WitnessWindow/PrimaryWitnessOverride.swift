import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary witness override is in its life cycle.
    enum PrimaryWitnessOverrideStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A primary witness override as the witness team keeps it.
    final class PrimaryWitnessOverride {
        var code: String
        var title: String
        var reviewer: String
        var specialty: String
        var unit: String
        var durationMinutes: Int
        var ownerID: String
        var maximum: Double
        var createdAt: Int
        var ceiling: Double
        var status: PrimaryWitnessOverrideStatus

        init(code: String, title: String, reviewer: String, specialty: String, unit: String, durationMinutes: Int, ownerID: String, maximum: Double, createdAt: Int, ceiling: Double, status: PrimaryWitnessOverrideStatus) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.specialty = specialty
            self.unit = unit
            self.durationMinutes = durationMinutes
            self.ownerID = ownerID
            self.maximum = maximum
            self.createdAt = createdAt
            self.ceiling = ceiling
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

        func canMoveTo(_ next: PrimaryWitnessOverrideStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == PrimaryWitnessOverrideStatus.closed
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

        func moveTo(_ next: PrimaryWitnessOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary witness override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary witness override") \(code)"
        }

        func netLoad() -> Double {
            return ((maximum - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryWitnessOverride {
            return PrimaryWitnessOverride(
                code: code,
                title: title,
                reviewer: reviewer,
                specialty: specialty,
                unit: unit,
                durationMinutes: durationMinutes,
                ownerID: ownerID,
                maximum: maximum,
                createdAt: createdAt,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a primary witness override in status draft.
    static func newPrimaryWitnessOverride(_ code: String, title: String) -> PrimaryWitnessOverride {
        return PrimaryWitnessOverride(
            code: code,
            title: title,
            reviewer: "",
            specialty: "",
            unit: "",
            durationMinutes: 0,
            ownerID: "",
            maximum: 0.0,
            createdAt: 0,
            ceiling: 0.0,
            status: PrimaryWitnessOverrideStatus.draft
        )
    }
}
