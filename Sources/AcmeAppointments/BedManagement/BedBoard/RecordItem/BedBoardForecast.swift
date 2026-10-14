import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board forecast is in its life cycle.
    enum BedBoardForecastStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One bed board forecast, with what the planners need to act on it.
    final class BedBoardForecast {
        var code: String
        var title: String
        var diagnosisCode: String
        var facility: String
        var channel: String
        var revision: Int
        var amount: Double
        var quantity: Int
        var allergy: String
        var reviewer: String
        var status: BedBoardForecastStatus

        init(code: String, title: String, diagnosisCode: String, facility: String, channel: String, revision: Int, amount: Double, quantity: Int, allergy: String, reviewer: String, status: BedBoardForecastStatus) {
            self.code = code
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.facility = facility
            self.channel = channel
            self.revision = revision
            self.amount = amount
            self.quantity = quantity
            self.allergy = allergy
            self.reviewer = reviewer
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

        func canMoveTo(_ next: BedBoardForecastStatus) -> Bool {
            switch status {
            case .idle:
                return next == BedBoardForecastStatus.draining || next == BedBoardForecastStatus.stopped
            case .warming:
                switch next {
                case .ready, .draining:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                switch next {
                case .draining:
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

        func moveTo(_ next: BedBoardForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func netLoad() -> Double {
            return (Double(revision) * amount * 100).rounded() / 100
        }

        func copyValue() -> BedBoardForecast {
            return BedBoardForecast(
                code: code,
                title: title,
                diagnosisCode: diagnosisCode,
                facility: facility,
                channel: channel,
                revision: revision,
                amount: amount,
                quantity: quantity,
                allergy: allergy,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a bed board forecast in status idle.
    static func newBedBoardForecast(_ code: String, title: String) -> BedBoardForecast {
        return BedBoardForecast(
            code: code,
            title: title,
            diagnosisCode: "",
            facility: "",
            channel: "",
            revision: 0,
            amount: 0.0,
            quantity: 0,
            allergy: "",
            reviewer: "",
            status: BedBoardForecastStatus.idle
        )
    }
}
