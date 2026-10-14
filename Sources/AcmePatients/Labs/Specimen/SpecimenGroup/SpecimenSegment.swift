import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen segment is in its life cycle.
    enum SpecimenSegmentStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A specimen segment as the specimen team keeps it.
    final class SpecimenSegment {
        var code: String
        var name: String
        var expiresAt: Int
        var startsAt: Int
        var currency: String
        var createdAt: Int
        var weight: Double
        var minimum: Double
        var status: SpecimenSegmentStatus

        init(code: String, name: String, expiresAt: Int, startsAt: Int, currency: String, createdAt: Int, weight: Double, minimum: Double, status: SpecimenSegmentStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.startsAt = startsAt
            self.currency = currency
            self.createdAt = createdAt
            self.weight = weight
            self.minimum = minimum
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

        func canMoveTo(_ next: SpecimenSegmentStatus) -> Bool {
            switch status {
            case .draft:
                return next == SpecimenSegmentStatus.closed
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == SpecimenSegmentStatus.closed
            case .suspended:
                return next == SpecimenSegmentStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SpecimenSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedLoad() -> Double {
            return ((Double(expiresAt) + Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenSegment {
            return SpecimenSegment(
                code: code,
                name: name,
                expiresAt: expiresAt,
                startsAt: startsAt,
                currency: currency,
                createdAt: createdAt,
                weight: weight,
                minimum: minimum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a specimen segment in status draft.
    static func newSpecimenSegment(_ code: String, name: String) -> SpecimenSegment {
        return SpecimenSegment(
            code: code,
            name: name,
            expiresAt: 0,
            startsAt: 0,
            currency: "",
            createdAt: 0,
            weight: 0.0,
            minimum: 0.0,
            status: SpecimenSegmentStatus.draft
        )
    }
}
