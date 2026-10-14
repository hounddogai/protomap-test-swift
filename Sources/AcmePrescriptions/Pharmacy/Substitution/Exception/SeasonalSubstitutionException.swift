import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a seasonal substitution exception is in its life cycle.
    enum SeasonalSubstitutionExceptionStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A seasonal substitution exception. Its code is unique within a tenant.
    final class SeasonalSubstitutionException {
        var code: String
        var name: String
        var encounterID: String
        var unit: String
        var refills: Int
        var specialty: String
        var floorValue: Double
        var graceDays: Int
        var title: String
        var status: SeasonalSubstitutionExceptionStatus

        init(code: String, name: String, encounterID: String, unit: String, refills: Int, specialty: String, floorValue: Double, graceDays: Int, title: String, status: SeasonalSubstitutionExceptionStatus) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.unit = unit
            self.refills = refills
            self.specialty = specialty
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.title = title
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

        func canMoveTo(_ next: SeasonalSubstitutionExceptionStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == SeasonalSubstitutionExceptionStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalSubstitutionExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal substitution exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((Double(graceDays) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> SeasonalSubstitutionException {
            return SeasonalSubstitutionException(
                code: code,
                name: name,
                encounterID: encounterID,
                unit: unit,
                refills: refills,
                specialty: specialty,
                floorValue: floorValue,
                graceDays: graceDays,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a seasonal substitution exception in status idle.
    static func newSeasonalSubstitutionException(_ code: String, name: String) -> SeasonalSubstitutionException {
        return SeasonalSubstitutionException(
            code: code,
            name: name,
            encounterID: "",
            unit: "",
            refills: 0,
            specialty: "",
            floorValue: 0.0,
            graceDays: 0,
            title: "",
            status: SeasonalSubstitutionExceptionStatus.idle
        )
    }
}
