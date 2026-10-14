import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board score is in its life cycle.
    enum BedBoardScoreStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A bed board score as the bed board team keeps it.
    final class BedBoardScore {
        var code: String
        var title: String
        var refills: Int
        var patientRef: String
        var score: Double
        var capacity: Int
        var currency: String
        var name: String
        var status: BedBoardScoreStatus

        init(code: String, title: String, refills: Int, patientRef: String, score: Double, capacity: Int, currency: String, name: String, status: BedBoardScoreStatus) {
            self.code = code
            self.title = title
            self.refills = refills
            self.patientRef = patientRef
            self.score = score
            self.capacity = capacity
            self.currency = currency
            self.name = name
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BedBoardScoreStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == BedBoardScoreStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardScoreStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board score \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedVolume() -> Double {
            return (Double(capacity) * Double(refills) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardScore {
            return BedBoardScore(
                code: code,
                title: title,
                refills: refills,
                patientRef: patientRef,
                score: score,
                capacity: capacity,
                currency: currency,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board score in status proposed.
    static func newBedBoardScore(_ code: String, title: String) -> BedBoardScore {
        return BedBoardScore(
            code: code,
            title: title,
            refills: 0,
            patientRef: "",
            score: 0.0,
            capacity: 0,
            currency: "",
            name: "",
            status: BedBoardScoreStatus.proposed
        )
    }
}
