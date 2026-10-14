import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board claim is in its life cycle.
    enum BedBoardClaimStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One bed board claim, with what the planners need to act on it.
    final class BedBoardClaim {
        var code: String
        var name: String
        var locale: String
        var batchSize: Int
        var amount: Double
        var specialty: String
        var ward: String
        var status: BedBoardClaimStatus

        init(code: String, name: String, locale: String, batchSize: Int, amount: Double, specialty: String, ward: String, status: BedBoardClaimStatus) {
            self.code = code
            self.name = name
            self.locale = locale
            self.batchSize = batchSize
            self.amount = amount
            self.specialty = specialty
            self.ward = ward
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

        func canMoveTo(_ next: BedBoardClaimStatus) -> Bool {
            switch status {
            case .new:
                return next == BedBoardClaimStatus.queued || next == BedBoardClaimStatus.done
            case .queued:
                switch next {
                case .running, .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == BedBoardClaimStatus.done || next == BedBoardClaimStatus.failed
            case .done:
                return next == BedBoardClaimStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BedBoardClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func projectedVolume() -> Double {
            return ((amount - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardClaim {
            return BedBoardClaim(
                code: code,
                name: name,
                locale: locale,
                batchSize: batchSize,
                amount: amount,
                specialty: specialty,
                ward: ward,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a bed board claim in status new.
    static func newBedBoardClaim(_ code: String, name: String) -> BedBoardClaim {
        return BedBoardClaim(
            code: code,
            name: name,
            locale: "",
            batchSize: 0,
            amount: 0.0,
            specialty: "",
            ward: "",
            status: BedBoardClaimStatus.new
        )
    }
}
