import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a manual isolation preference is in its life cycle.
    enum ManualIsolationPreferenceStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A manual isolation preference as the isolation team keeps it.
    final class ManualIsolationPreference {
        var code: String
        var name: String
        var notes: String
        var currency: String
        var dosageMg: Double
        var country: String
        var procedureCode: String
        var score: Double
        var startsAt: Int
        var bed: String
        var status: ManualIsolationPreferenceStatus

        init(code: String, name: String, notes: String, currency: String, dosageMg: Double, country: String, procedureCode: String, score: Double, startsAt: Int, bed: String, status: ManualIsolationPreferenceStatus) {
            self.code = code
            self.name = name
            self.notes = notes
            self.currency = currency
            self.dosageMg = dosageMg
            self.country = country
            self.procedureCode = procedureCode
            self.score = score
            self.startsAt = startsAt
            self.bed = bed
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

        func canMoveTo(_ next: ManualIsolationPreferenceStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: ManualIsolationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual isolation preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedValue() -> Double {
            return (dosageMg * Double(startsAt) * 100).rounded() / 100
        }

        func copyValue() -> ManualIsolationPreference {
            return ManualIsolationPreference(
                code: code,
                name: name,
                notes: notes,
                currency: currency,
                dosageMg: dosageMg,
                country: country,
                procedureCode: procedureCode,
                score: score,
                startsAt: startsAt,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a manual isolation preference in status idle.
    static func newManualIsolationPreference(_ code: String, name: String) -> ManualIsolationPreference {
        return ManualIsolationPreference(
            code: code,
            name: name,
            notes: "",
            currency: "",
            dosageMg: 0.0,
            country: "",
            procedureCode: "",
            score: 0.0,
            startsAt: 0,
            bed: "",
            status: ManualIsolationPreferenceStatus.idle
        )
    }
}
