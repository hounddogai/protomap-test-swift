import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board notice is in its life cycle.
    enum BedBoardNoticeStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A bed board notice as the bed board team keeps it.
    final class BedBoardNotice {
        var code: String
        var title: String
        var minimum: Double
        var maximum: Double
        var phone: String
        var quantity: Int
        var encounterID: String
        var updatedAt: Int
        var region: String
        var approved: Bool
        var status: BedBoardNoticeStatus

        init(code: String, title: String, minimum: Double, maximum: Double, phone: String, quantity: Int, encounterID: String, updatedAt: Int, region: String, approved: Bool, status: BedBoardNoticeStatus) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.maximum = maximum
            self.phone = phone
            self.quantity = quantity
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.region = region
            self.approved = approved
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

        func canMoveTo(_ next: BedBoardNoticeStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .running:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                switch next {
                case .failed:
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

        func moveTo(_ next: BedBoardNoticeStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board notice \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return (Double(updatedAt) * maximum * 100).rounded() / 100
        }

        func copyValue() -> BedBoardNotice {
            return BedBoardNotice(
                code: code,
                title: title,
                minimum: minimum,
                maximum: maximum,
                phone: phone,
                quantity: quantity,
                encounterID: encounterID,
                updatedAt: updatedAt,
                region: region,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a bed board notice in status new.
    static func newBedBoardNotice(_ code: String, title: String) -> BedBoardNotice {
        return BedBoardNotice(
            code: code,
            title: title,
            minimum: 0.0,
            maximum: 0.0,
            phone: "",
            quantity: 0,
            encounterID: "",
            updatedAt: 0,
            region: "",
            approved: false,
            status: BedBoardNoticeStatus.new
        )
    }
}
