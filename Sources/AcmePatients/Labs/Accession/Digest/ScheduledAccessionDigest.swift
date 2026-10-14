import AcmePlatform
import Foundation

extension Labs {
    /// Where a scheduled accession digest is in its life cycle.
    enum ScheduledAccessionDigestStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a scheduled accession digest and its current status.
    final class ScheduledAccessionDigest {
        var code: String
        var name: String
        var bed: String
        var batchSize: Int
        var unit: String
        var quantity: Int
        var source: String
        var externalRef: String
        var status: ScheduledAccessionDigestStatus

        init(code: String, name: String, bed: String, batchSize: Int, unit: String, quantity: Int, source: String, externalRef: String, status: ScheduledAccessionDigestStatus) {
            self.code = code
            self.name = name
            self.bed = bed
            self.batchSize = batchSize
            self.unit = unit
            self.quantity = quantity
            self.source = source
            self.externalRef = externalRef
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

        func canMoveTo(_ next: ScheduledAccessionDigestStatus) -> Bool {
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
                case .running, .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == ScheduledAccessionDigestStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledAccessionDigestStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled accession digest \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("scheduled accession digest") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(batchSize) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledAccessionDigest {
            return ScheduledAccessionDigest(
                code: code,
                name: name,
                bed: bed,
                batchSize: batchSize,
                unit: unit,
                quantity: quantity,
                source: source,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a scheduled accession digest in status new.
    static func newScheduledAccessionDigest(_ code: String, name: String) -> ScheduledAccessionDigest {
        return ScheduledAccessionDigest(
            code: code,
            name: name,
            bed: "",
            batchSize: 0,
            unit: "",
            quantity: 0,
            source: "",
            externalRef: "",
            status: ScheduledAccessionDigestStatus.new
        )
    }
}
