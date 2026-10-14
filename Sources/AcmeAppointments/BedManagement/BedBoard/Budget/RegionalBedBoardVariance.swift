import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional bed board variance is in its life cycle.
    enum RegionalBedBoardVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a regional bed board variance and its current status.
    final class RegionalBedBoardVariance {
        var code: String
        var title: String
        var startsAt: Int
        var timezone: String
        var unit: String
        var margin: Double
        var contactEmail: String
        var pinned: Bool
        var weight: Double
        var copay: Double
        var status: RegionalBedBoardVarianceStatus

        init(code: String, title: String, startsAt: Int, timezone: String, unit: String, margin: Double, contactEmail: String, pinned: Bool, weight: Double, copay: Double, status: RegionalBedBoardVarianceStatus) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.timezone = timezone
            self.unit = unit
            self.margin = margin
            self.contactEmail = contactEmail
            self.pinned = pinned
            self.weight = weight
            self.copay = copay
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

        func canMoveTo(_ next: RegionalBedBoardVarianceStatus) -> Bool {
            switch status {
            case .created:
                return next == RegionalBedBoardVarianceStatus.validated || next == RegionalBedBoardVarianceStatus.retired
            case .validated:
                switch next {
                case .retired:
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

        func moveTo(_ next: RegionalBedBoardVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional bed board variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netValue() -> Double {
            return ((weight - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalBedBoardVariance {
            return RegionalBedBoardVariance(
                code: code,
                title: title,
                startsAt: startsAt,
                timezone: timezone,
                unit: unit,
                margin: margin,
                contactEmail: contactEmail,
                pinned: pinned,
                weight: weight,
                copay: copay,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a regional bed board variance in status created.
    static func newRegionalBedBoardVariance(_ code: String, title: String) -> RegionalBedBoardVariance {
        return RegionalBedBoardVariance(
            code: code,
            title: title,
            startsAt: 0,
            timezone: "",
            unit: "",
            margin: 0.0,
            contactEmail: "",
            pinned: false,
            weight: 0.0,
            copay: 0.0,
            status: RegionalBedBoardVarianceStatus.created
        )
    }
}
