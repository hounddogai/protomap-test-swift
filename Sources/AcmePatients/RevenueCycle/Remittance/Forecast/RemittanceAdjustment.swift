import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance adjustment is in its life cycle.
    enum RemittanceAdjustmentStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A remittance adjustment as the remittance team keeps it.
    final class RemittanceAdjustment {
        var code: String
        var label: String
        var checksum: String
        var segment: String
        var notes: String
        var quantity: Int
        var maximum: Double
        var tags: [String]
        var limit: Int
        var specialty: String
        var rate: Double
        var status: RemittanceAdjustmentStatus

        init(code: String, label: String, checksum: String, segment: String, notes: String, quantity: Int, maximum: Double, tags: [String], limit: Int, specialty: String, rate: Double, status: RemittanceAdjustmentStatus) {
            self.code = code
            self.label = label
            self.checksum = checksum
            self.segment = segment
            self.notes = notes
            self.quantity = quantity
            self.maximum = maximum
            self.tags = tags
            self.limit = limit
            self.specialty = specialty
            self.rate = rate
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

        func canMoveTo(_ next: RemittanceAdjustmentStatus) -> Bool {
            switch status {
            case .new:
                return next == RemittanceAdjustmentStatus.done
            case .queued:
                return next == RemittanceAdjustmentStatus.done || next == RemittanceAdjustmentStatus.failed
            case .running:
                return next == RemittanceAdjustmentStatus.done || next == RemittanceAdjustmentStatus.failed
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

        func moveTo(_ next: RemittanceAdjustmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance adjustment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("remittance adjustment") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netExposure() -> Double {
            return ((Double(quantity) - Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceAdjustment {
            return RemittanceAdjustment(
                code: code,
                label: label,
                checksum: checksum,
                segment: segment,
                notes: notes,
                quantity: quantity,
                maximum: maximum,
                tags: tags,
                limit: limit,
                specialty: specialty,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a remittance adjustment in status new.
    static func newRemittanceAdjustment(_ code: String, label: String) -> RemittanceAdjustment {
        return RemittanceAdjustment(
            code: code,
            label: label,
            checksum: "",
            segment: "",
            notes: "",
            quantity: 0,
            maximum: 0.0,
            tags: [],
            limit: 0,
            specialty: "",
            rate: 0.0,
            status: RemittanceAdjustmentStatus.new
        )
    }
}
