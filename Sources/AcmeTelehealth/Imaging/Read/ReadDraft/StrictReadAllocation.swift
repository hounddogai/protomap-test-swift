import AcmePlatform
import Foundation

extension Imaging {
    /// Where a strict read allocation is in its life cycle.
    enum StrictReadAllocationStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A strict read allocation as the read team keeps it.
    final class StrictReadAllocation {
        var code: String
        var name: String
        var facility: String
        var batchSize: Int
        var region: String
        var pinned: Bool
        var copay: Double
        var createdAt: Int
        var rate: Double
        var status: StrictReadAllocationStatus

        init(code: String, name: String, facility: String, batchSize: Int, region: String, pinned: Bool, copay: Double, createdAt: Int, rate: Double, status: StrictReadAllocationStatus) {
            self.code = code
            self.name = name
            self.facility = facility
            self.batchSize = batchSize
            self.region = region
            self.pinned = pinned
            self.copay = copay
            self.createdAt = createdAt
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictReadAllocationStatus) -> Bool {
            switch status {
            case .created:
                return next == StrictReadAllocationStatus.published || next == StrictReadAllocationStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == StrictReadAllocationStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StrictReadAllocationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict read allocation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("strict read allocation") \(code)"
        }

        func netValue() -> Double {
            return (Double(createdAt) * copay * 100).rounded() / 100
        }

        func copyValue() -> StrictReadAllocation {
            return StrictReadAllocation(
                code: code,
                name: name,
                facility: facility,
                batchSize: batchSize,
                region: region,
                pinned: pinned,
                copay: copay,
                createdAt: createdAt,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a strict read allocation in status created.
    static func newStrictReadAllocation(_ code: String, name: String) -> StrictReadAllocation {
        return StrictReadAllocation(
            code: code,
            name: name,
            facility: "",
            batchSize: 0,
            region: "",
            pinned: false,
            copay: 0.0,
            createdAt: 0,
            rate: 0.0,
            status: StrictReadAllocationStatus.created
        )
    }
}
