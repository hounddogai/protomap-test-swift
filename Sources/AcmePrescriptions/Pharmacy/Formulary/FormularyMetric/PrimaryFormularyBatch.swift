import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a primary formulary batch is in its life cycle.
    enum PrimaryFormularyBatchStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a primary formulary batch and its current status.
    final class PrimaryFormularyBatch {
        var code: String
        var title: String
        var facility: String
        var ward: String
        var quantity: Int
        var createdAt: Int
        var weight: Double
        var encounterID: String
        var visible: Bool
        var margin: Double
        var status: PrimaryFormularyBatchStatus

        init(code: String, title: String, facility: String, ward: String, quantity: Int, createdAt: Int, weight: Double, encounterID: String, visible: Bool, margin: Double, status: PrimaryFormularyBatchStatus) {
            self.code = code
            self.title = title
            self.facility = facility
            self.ward = ward
            self.quantity = quantity
            self.createdAt = createdAt
            self.weight = weight
            self.encounterID = encounterID
            self.visible = visible
            self.margin = margin
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

        func canMoveTo(_ next: PrimaryFormularyBatchStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == PrimaryFormularyBatchStatus.done
            case .running:
                return next == PrimaryFormularyBatchStatus.done
            case .done:
                return next == PrimaryFormularyBatchStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryFormularyBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary formulary batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("primary formulary batch") \(code)"
        }

        func effectiveVolume() -> Double {
            return ((weight - Double(createdAt)) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryFormularyBatch {
            return PrimaryFormularyBatch(
                code: code,
                title: title,
                facility: facility,
                ward: ward,
                quantity: quantity,
                createdAt: createdAt,
                weight: weight,
                encounterID: encounterID,
                visible: visible,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a primary formulary batch in status new.
    static func newPrimaryFormularyBatch(_ code: String, title: String) -> PrimaryFormularyBatch {
        return PrimaryFormularyBatch(
            code: code,
            title: title,
            facility: "",
            ward: "",
            quantity: 0,
            createdAt: 0,
            weight: 0.0,
            encounterID: "",
            visible: false,
            margin: 0.0,
            status: PrimaryFormularyBatchStatus.new
        )
    }
}
