import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict bed board variance is in its life cycle.
    enum StrictBedBoardVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One strict bed board variance, with what the planners need to act on it.
    final class StrictBedBoardVariance {
        var code: String
        var name: String
        var visible: Bool
        var margin: Double
        var budget: Double
        var rate: Double
        var currency: String
        var phone: String
        var status: StrictBedBoardVarianceStatus

        init(code: String, name: String, visible: Bool, margin: Double, budget: Double, rate: Double, currency: String, phone: String, status: StrictBedBoardVarianceStatus) {
            self.code = code
            self.name = name
            self.visible = visible
            self.margin = margin
            self.budget = budget
            self.rate = rate
            self.currency = currency
            self.phone = phone
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

        func canMoveTo(_ next: StrictBedBoardVarianceStatus) -> Bool {
            switch status {
            case .draft:
                return next == StrictBedBoardVarianceStatus.pending || next == StrictBedBoardVarianceStatus.active
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StrictBedBoardVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict bed board variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func projectedVolume() -> Double {
            return ((budget + rate) * 100).rounded() / 100
        }

        func copyValue() -> StrictBedBoardVariance {
            return StrictBedBoardVariance(
                code: code,
                name: name,
                visible: visible,
                margin: margin,
                budget: budget,
                rate: rate,
                currency: currency,
                phone: phone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a strict bed board variance in status draft.
    static func newStrictBedBoardVariance(_ code: String, name: String) -> StrictBedBoardVariance {
        return StrictBedBoardVariance(
            code: code,
            name: name,
            visible: false,
            margin: 0.0,
            budget: 0.0,
            rate: 0.0,
            currency: "",
            phone: "",
            status: StrictBedBoardVarianceStatus.draft
        )
    }
}
