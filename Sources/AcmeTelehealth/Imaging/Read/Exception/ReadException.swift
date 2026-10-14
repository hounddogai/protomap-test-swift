import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read exception is in its life cycle.
    enum ReadExceptionStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A read exception as the read team keeps it.
    final class ReadException {
        var code: String
        var label: String
        var weight: Double
        var priority: Int
        var clinicianID: String
        var country: String
        var payer: String
        var quantity: Int
        var ownerID: String
        var status: ReadExceptionStatus

        init(code: String, label: String, weight: Double, priority: Int, clinicianID: String, country: String, payer: String, quantity: Int, ownerID: String, status: ReadExceptionStatus) {
            self.code = code
            self.label = label
            self.weight = weight
            self.priority = priority
            self.clinicianID = clinicianID
            self.country = country
            self.payer = payer
            self.quantity = quantity
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ReadExceptionStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .queued, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == ReadExceptionStatus.running || next == ReadExceptionStatus.done
            case .running:
                return next == ReadExceptionStatus.failed
            case .done:
                return next == ReadExceptionStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReadExceptionStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read exception \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func adjustedVolume() -> Double {
            return ((weight - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> ReadException {
            return ReadException(
                code: code,
                label: label,
                weight: weight,
                priority: priority,
                clinicianID: clinicianID,
                country: country,
                payer: payer,
                quantity: quantity,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a read exception in status new.
    static func newReadException(_ code: String, label: String) -> ReadException {
        return ReadException(
            code: code,
            label: label,
            weight: 0.0,
            priority: 0,
            clinicianID: "",
            country: "",
            payer: "",
            quantity: 0,
            ownerID: "",
            status: ReadExceptionStatus.new
        )
    }
}
