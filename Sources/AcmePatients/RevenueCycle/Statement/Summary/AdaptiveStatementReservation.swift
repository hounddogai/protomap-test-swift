import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a adaptive statement reservation is in its life cycle.
    enum AdaptiveStatementReservationStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A adaptive statement reservation as the statement team keeps it.
    final class AdaptiveStatementReservation {
        var code: String
        var name: String
        var batchSize: Int
        var ceiling: Double
        var quantity: Int
        var graceDays: Int
        var bed: String
        var payer: String
        var channel: String
        var description: String
        var status: AdaptiveStatementReservationStatus

        init(code: String, name: String, batchSize: Int, ceiling: Double, quantity: Int, graceDays: Int, bed: String, payer: String, channel: String, description: String, status: AdaptiveStatementReservationStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.ceiling = ceiling
            self.quantity = quantity
            self.graceDays = graceDays
            self.bed = bed
            self.payer = payer
            self.channel = channel
            self.description = description
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

        func canMoveTo(_ next: AdaptiveStatementReservationStatus) -> Bool {
            switch status {
            case .new:
                return next == AdaptiveStatementReservationStatus.queued || next == AdaptiveStatementReservationStatus.failed
            case .queued:
                return next == AdaptiveStatementReservationStatus.done
            case .running:
                return next == AdaptiveStatementReservationStatus.done
            case .done:
                return next == AdaptiveStatementReservationStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveStatementReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive statement reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedExposure() -> Double {
            return ((Double(graceDays) + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveStatementReservation {
            return AdaptiveStatementReservation(
                code: code,
                name: name,
                batchSize: batchSize,
                ceiling: ceiling,
                quantity: quantity,
                graceDays: graceDays,
                bed: bed,
                payer: payer,
                channel: channel,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a adaptive statement reservation in status new.
    static func newAdaptiveStatementReservation(_ code: String, name: String) -> AdaptiveStatementReservation {
        return AdaptiveStatementReservation(
            code: code,
            name: name,
            batchSize: 0,
            ceiling: 0.0,
            quantity: 0,
            graceDays: 0,
            bed: "",
            payer: "",
            channel: "",
            description: "",
            status: AdaptiveStatementReservationStatus.new
        )
    }
}
