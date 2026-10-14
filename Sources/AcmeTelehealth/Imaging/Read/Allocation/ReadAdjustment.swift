import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read adjustment is in its life cycle.
    enum ReadAdjustmentStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A read adjustment as the read team keeps it.
    final class ReadAdjustment {
        var code: String
        var title: String
        var ownerID: String
        var sequence: Int
        var minimum: Double
        var refills: Int
        var amount: Double
        var name: String
        var currency: String
        var expiresAt: Int
        var windowDays: Int
        var status: ReadAdjustmentStatus

        init(code: String, title: String, ownerID: String, sequence: Int, minimum: Double, refills: Int, amount: Double, name: String, currency: String, expiresAt: Int, windowDays: Int, status: ReadAdjustmentStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.sequence = sequence
            self.minimum = minimum
            self.refills = refills
            self.amount = amount
            self.name = name
            self.currency = currency
            self.expiresAt = expiresAt
            self.windowDays = windowDays
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

        func canMoveTo(_ next: ReadAdjustmentStatus) -> Bool {
            switch status {
            case .idle:
                return next == ReadAdjustmentStatus.warming || next == ReadAdjustmentStatus.stopped
            case .warming:
                return next == ReadAdjustmentStatus.ready || next == ReadAdjustmentStatus.stopped
            case .ready:
                return next == ReadAdjustmentStatus.draining || next == ReadAdjustmentStatus.stopped
            case .draining:
                return next == ReadAdjustmentStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("read adjustment") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(windowDays) - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> ReadAdjustment {
            return ReadAdjustment(
                code: code,
                title: title,
                ownerID: ownerID,
                sequence: sequence,
                minimum: minimum,
                refills: refills,
                amount: amount,
                name: name,
                currency: currency,
                expiresAt: expiresAt,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a read adjustment in status idle.
    static func newReadAdjustment(_ code: String, title: String) -> ReadAdjustment {
        return ReadAdjustment(
            code: code,
            title: title,
            ownerID: "",
            sequence: 0,
            minimum: 0.0,
            refills: 0,
            amount: 0.0,
            name: "",
            currency: "",
            expiresAt: 0,
            windowDays: 0,
            status: ReadAdjustmentStatus.idle
        )
    }
}
