import AcmePlatform
import Foundation

extension Labs {
    /// Where a capped result override is in its life cycle.
    enum CappedResultOverrideStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A capped result override as the result team keeps it.
    final class CappedResultOverride {
        var code: String
        var name: String
        var country: String
        var specialty: String
        var acuity: Int
        var endsAt: Int
        var batchSize: Int
        var status: CappedResultOverrideStatus

        init(code: String, name: String, country: String, specialty: String, acuity: Int, endsAt: Int, batchSize: Int, status: CappedResultOverrideStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.specialty = specialty
            self.acuity = acuity
            self.endsAt = endsAt
            self.batchSize = batchSize
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CappedResultOverrideStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == CappedResultOverrideStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == CappedResultOverrideStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedResultOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped result override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedTotal() -> Double {
            return (Double(endsAt) * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> CappedResultOverride {
            return CappedResultOverride(
                code: code,
                name: name,
                country: country,
                specialty: specialty,
                acuity: acuity,
                endsAt: endsAt,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a capped result override in status planned.
    static func newCappedResultOverride(_ code: String, name: String) -> CappedResultOverride {
        return CappedResultOverride(
            code: code,
            name: name,
            country: "",
            specialty: "",
            acuity: 0,
            endsAt: 0,
            batchSize: 0,
            status: CappedResultOverrideStatus.planned
        )
    }
}
