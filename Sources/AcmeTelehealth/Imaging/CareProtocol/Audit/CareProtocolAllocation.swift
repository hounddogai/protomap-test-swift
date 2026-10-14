import AcmePlatform
import Foundation

extension Imaging {
    /// Where a care protocol allocation is in its life cycle.
    enum CareProtocolAllocationStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One care protocol allocation, with what the planners need to act on it.
    final class CareProtocolAllocation {
        var code: String
        var name: String
        var dosageMg: Double
        var retries: Int
        var sequence: Int
        var quantity: Int
        var description: String
        var batchSize: Int
        var windowDays: Int
        var status: CareProtocolAllocationStatus

        init(code: String, name: String, dosageMg: Double, retries: Int, sequence: Int, quantity: Int, description: String, batchSize: Int, windowDays: Int, status: CareProtocolAllocationStatus) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.retries = retries
            self.sequence = sequence
            self.quantity = quantity
            self.description = description
            self.batchSize = batchSize
            self.windowDays = windowDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareProtocolAllocationStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == CareProtocolAllocationStatus.resolved || next == CareProtocolAllocationStatus.reopened
            case .resolved:
                return next == CareProtocolAllocationStatus.reopened || next == CareProtocolAllocationStatus.archived
            case .reopened:
                return next == CareProtocolAllocationStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareProtocolAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care protocol allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func projectedExposure() -> Double {
            return ((Double(retries) + Double(sequence)) * 100).rounded() / 100
        }

        func copyValue() -> CareProtocolAllocation {
            return CareProtocolAllocation(
                code: code,
                name: name,
                dosageMg: dosageMg,
                retries: retries,
                sequence: sequence,
                quantity: quantity,
                description: description,
                batchSize: batchSize,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a care protocol allocation in status open.
    static func newCareProtocolAllocation(_ code: String, name: String) -> CareProtocolAllocation {
        return CareProtocolAllocation(
            code: code,
            name: name,
            dosageMg: 0.0,
            retries: 0,
            sequence: 0,
            quantity: 0,
            description: "",
            batchSize: 0,
            windowDays: 0,
            status: CareProtocolAllocationStatus.`open`
        )
    }
}
