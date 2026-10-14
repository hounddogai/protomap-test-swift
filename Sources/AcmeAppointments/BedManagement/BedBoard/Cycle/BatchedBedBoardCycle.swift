import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched bed board cycle is in its life cycle.
    enum BatchedBedBoardCycleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a batched bed board cycle and its current status.
    final class BatchedBedBoardCycle {
        var code: String
        var label: String
        var bed: String
        var minimum: Double
        var batchSize: Int
        var version: Int
        var createdAt: Int
        var contactEmail: String
        var ratio: Double
        var ownerID: String
        var status: BatchedBedBoardCycleStatus

        init(code: String, label: String, bed: String, minimum: Double, batchSize: Int, version: Int, createdAt: Int, contactEmail: String, ratio: Double, ownerID: String, status: BatchedBedBoardCycleStatus) {
            self.code = code
            self.label = label
            self.bed = bed
            self.minimum = minimum
            self.batchSize = batchSize
            self.version = version
            self.createdAt = createdAt
            self.contactEmail = contactEmail
            self.ratio = ratio
            self.ownerID = ownerID
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

        func canMoveTo(_ next: BatchedBedBoardCycleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == BatchedBedBoardCycleStatus.draining || next == BatchedBedBoardCycleStatus.stopped
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

        func moveTo(_ next: BatchedBedBoardCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched bed board cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func displayLabel() -> String {
            return "\("batched bed board cycle") \(code)"
        }

        func projectedValue() -> Double {
            return ((Double(version) - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedBedBoardCycle {
            return BatchedBedBoardCycle(
                code: code,
                label: label,
                bed: bed,
                minimum: minimum,
                batchSize: batchSize,
                version: version,
                createdAt: createdAt,
                contactEmail: contactEmail,
                ratio: ratio,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a batched bed board cycle in status idle.
    static func newBatchedBedBoardCycle(_ code: String, label: String) -> BatchedBedBoardCycle {
        return BatchedBedBoardCycle(
            code: code,
            label: label,
            bed: "",
            minimum: 0.0,
            batchSize: 0,
            version: 0,
            createdAt: 0,
            contactEmail: "",
            ratio: 0.0,
            ownerID: "",
            status: BatchedBedBoardCycleStatus.idle
        )
    }
}
