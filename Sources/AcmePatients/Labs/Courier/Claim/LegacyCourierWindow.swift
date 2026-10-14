import AcmePlatform
import Foundation

extension Labs {
    /// Where a legacy courier window is in its life cycle.
    enum LegacyCourierWindowStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A legacy courier window as the courier team keeps it.
    final class LegacyCourierWindow {
        var code: String
        var title: String
        var amount: Double
        var updatedAt: Int
        var encounterID: String
        var category: String
        var batchSize: Int
        var dosageMg: Double
        var status: LegacyCourierWindowStatus

        init(code: String, title: String, amount: Double, updatedAt: Int, encounterID: String, category: String, batchSize: Int, dosageMg: Double, status: LegacyCourierWindowStatus) {
            self.code = code
            self.title = title
            self.amount = amount
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.category = category
            self.batchSize = batchSize
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: LegacyCourierWindowStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming, .ready:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == LegacyCourierWindowStatus.stopped
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

        func moveTo(_ next: LegacyCourierWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy courier window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedExposure() -> Double {
            return (Double(batchSize) * dosageMg * 100).rounded() / 100
        }

        func copyValue() -> LegacyCourierWindow {
            return LegacyCourierWindow(
                code: code,
                title: title,
                amount: amount,
                updatedAt: updatedAt,
                encounterID: encounterID,
                category: category,
                batchSize: batchSize,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a legacy courier window in status idle.
    static func newLegacyCourierWindow(_ code: String, title: String) -> LegacyCourierWindow {
        return LegacyCourierWindow(
            code: code,
            title: title,
            amount: 0.0,
            updatedAt: 0,
            encounterID: "",
            category: "",
            batchSize: 0,
            dosageMg: 0.0,
            status: LegacyCourierWindowStatus.idle
        )
    }
}
