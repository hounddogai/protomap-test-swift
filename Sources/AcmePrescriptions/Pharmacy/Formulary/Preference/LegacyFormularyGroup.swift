import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a legacy formulary group is in its life cycle.
    enum LegacyFormularyGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One legacy formulary group, with what the planners need to act on it.
    final class LegacyFormularyGroup {
        var code: String
        var title: String
        var attempts: Int
        var refills: Int
        var specialty: String
        var floorValue: Double
        var priority: Int
        var batchSize: Int
        var country: String
        var rate: Double
        var status: LegacyFormularyGroupStatus

        init(code: String, title: String, attempts: Int, refills: Int, specialty: String, floorValue: Double, priority: Int, batchSize: Int, country: String, rate: Double, status: LegacyFormularyGroupStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.refills = refills
            self.specialty = specialty
            self.floorValue = floorValue
            self.priority = priority
            self.batchSize = batchSize
            self.country = country
            self.rate = rate
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

        func canMoveTo(_ next: LegacyFormularyGroupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LegacyFormularyGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy formulary group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedLoad() -> Double {
            return ((Double(attempts) - rate) * 100).rounded() / 100
        }

        func copyValue() -> LegacyFormularyGroup {
            return LegacyFormularyGroup(
                code: code,
                title: title,
                attempts: attempts,
                refills: refills,
                specialty: specialty,
                floorValue: floorValue,
                priority: priority,
                batchSize: batchSize,
                country: country,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a legacy formulary group in status created.
    static func newLegacyFormularyGroup(_ code: String, title: String) -> LegacyFormularyGroup {
        return LegacyFormularyGroup(
            code: code,
            title: title,
            attempts: 0,
            refills: 0,
            specialty: "",
            floorValue: 0.0,
            priority: 0,
            batchSize: 0,
            country: "",
            rate: 0.0,
            status: LegacyFormularyGroupStatus.created
        )
    }
}
