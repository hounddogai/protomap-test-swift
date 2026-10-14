import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board tier is in its life cycle.
    enum BedBoardTierStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// One bed board tier, with what the planners need to act on it.
    final class BedBoardTier {
        var code: String
        var title: String
        var quantity: Int
        var label: String
        var phone: String
        var batchSize: Int
        var status: BedBoardTierStatus

        init(code: String, title: String, quantity: Int, label: String, phone: String, batchSize: Int, status: BedBoardTierStatus) {
            self.code = code
            self.title = title
            self.quantity = quantity
            self.label = label
            self.phone = phone
            self.batchSize = batchSize
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

        func canMoveTo(_ next: BedBoardTierStatus) -> Bool {
            switch status {
            case .idle:
                return next == BedBoardTierStatus.stopped
            case .warming:
                return next == BedBoardTierStatus.ready
            case .ready:
                return next == BedBoardTierStatus.draining || next == BedBoardTierStatus.stopped
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

        func moveTo(_ next: BedBoardTierStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board tier \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func projectedTotal() -> Double {
            return ((Double(quantity) + Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> BedBoardTier {
            return BedBoardTier(
                code: code,
                title: title,
                quantity: quantity,
                label: label,
                phone: phone,
                batchSize: batchSize,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a bed board tier in status idle.
    static func newBedBoardTier(_ code: String, title: String) -> BedBoardTier {
        return BedBoardTier(
            code: code,
            title: title,
            quantity: 0,
            label: "",
            phone: "",
            batchSize: 0,
            status: BedBoardTierStatus.idle
        )
    }
}
