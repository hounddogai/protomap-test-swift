import AcmePlatform
import Foundation

extension Labs {
    /// Where a accession rollup is in its life cycle.
    enum AccessionRollupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One accession rollup, with what the planners need to act on it.
    final class AccessionRollup {
        var code: String
        var name: String
        var discount: Double
        var encounterID: String
        var segment: String
        var phone: String
        var startsAt: Int
        var status: AccessionRollupStatus

        init(code: String, name: String, discount: Double, encounterID: String, segment: String, phone: String, startsAt: Int, status: AccessionRollupStatus) {
            self.code = code
            self.name = name
            self.discount = discount
            self.encounterID = encounterID
            self.segment = segment
            self.phone = phone
            self.startsAt = startsAt
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

        func canMoveTo(_ next: AccessionRollupStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AccessionRollupStatus.published || next == AccessionRollupStatus.retired
            case .published:
                return next == AccessionRollupStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AccessionRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("accession rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("accession rollup") \(code)"
        }

        func projectedVolume() -> Double {
            return ((discount - Double(startsAt)) * 100).rounded() / 100
        }

        func copyValue() -> AccessionRollup {
            return AccessionRollup(
                code: code,
                name: name,
                discount: discount,
                encounterID: encounterID,
                segment: segment,
                phone: phone,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a accession rollup in status created.
    static func newAccessionRollup(_ code: String, name: String) -> AccessionRollup {
        return AccessionRollup(
            code: code,
            name: name,
            discount: 0.0,
            encounterID: "",
            segment: "",
            phone: "",
            startsAt: 0,
            status: AccessionRollupStatus.created
        )
    }
}
