import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen profile is in its life cycle.
    enum SpecimenProfileStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A specimen profile. Its code is unique within a tenant.
    final class SpecimenProfile {
        var code: String
        var name: String
        var payer: String
        var startsAt: Int
        var amount: Double
        var ward: String
        var expiresAt: Int
        var batchSize: Int
        var reviewer: String
        var floorValue: Double
        var status: SpecimenProfileStatus

        init(code: String, name: String, payer: String, startsAt: Int, amount: Double, ward: String, expiresAt: Int, batchSize: Int, reviewer: String, floorValue: Double, status: SpecimenProfileStatus) {
            self.code = code
            self.name = name
            self.payer = payer
            self.startsAt = startsAt
            self.amount = amount
            self.ward = ward
            self.expiresAt = expiresAt
            self.batchSize = batchSize
            self.reviewer = reviewer
            self.floorValue = floorValue
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

        func canMoveTo(_ next: SpecimenProfileStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == SpecimenProfileStatus.completed || next == SpecimenProfileStatus.cancelled
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: SpecimenProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("specimen profile") \(code)"
        }

        func effectiveLoad() -> Double {
            return ((floorValue - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> SpecimenProfile {
            return SpecimenProfile(
                code: code,
                name: name,
                payer: payer,
                startsAt: startsAt,
                amount: amount,
                ward: ward,
                expiresAt: expiresAt,
                batchSize: batchSize,
                reviewer: reviewer,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a specimen profile in status planned.
    static func newSpecimenProfile(_ code: String, name: String) -> SpecimenProfile {
        return SpecimenProfile(
            code: code,
            name: name,
            payer: "",
            startsAt: 0,
            amount: 0.0,
            ward: "",
            expiresAt: 0,
            batchSize: 0,
            reviewer: "",
            floorValue: 0.0,
            status: SpecimenProfileStatus.planned
        )
    }
}
