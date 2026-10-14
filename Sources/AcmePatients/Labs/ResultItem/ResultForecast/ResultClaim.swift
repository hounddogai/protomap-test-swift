import AcmePlatform
import Foundation

extension Labs {
    /// Where a result claim is in its life cycle.
    enum ResultClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One result claim, with what the planners need to act on it.
    final class ResultClaim {
        var code: String
        var title: String
        var ward: String
        var diagnosisCode: String
        var region: String
        var quantity: Int
        var status: ResultClaimStatus

        init(code: String, title: String, ward: String, diagnosisCode: String, region: String, quantity: Int, status: ResultClaimStatus) {
            self.code = code
            self.title = title
            self.ward = ward
            self.diagnosisCode = diagnosisCode
            self.region = region
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ResultClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == ResultClaimStatus.queued
            case .queued:
                return next == ResultClaimStatus.running || next == ResultClaimStatus.done
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ResultClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> ResultClaim {
            return ResultClaim(
                code: code,
                title: title,
                ward: ward,
                diagnosisCode: diagnosisCode,
                region: region,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a result claim in status new.
    static func newResultClaim(_ code: String, title: String) -> ResultClaim {
        return ResultClaim(
            code: code,
            title: title,
            ward: "",
            diagnosisCode: "",
            region: "",
            quantity: 0,
            status: ResultClaimStatus.new
        )
    }
}
