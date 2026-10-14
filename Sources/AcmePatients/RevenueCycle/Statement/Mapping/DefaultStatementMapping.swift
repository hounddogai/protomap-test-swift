import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default statement mapping is in its life cycle.
    enum DefaultStatementMappingStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A default statement mapping as the statement team keeps it.
    final class DefaultStatementMapping {
        var code: String
        var label: String
        var floorValue: Double
        var approved: Bool
        var pinned: Bool
        var batchSize: Int
        var allergy: String
        var status: DefaultStatementMappingStatus

        init(code: String, label: String, floorValue: Double, approved: Bool, pinned: Bool, batchSize: Int, allergy: String, status: DefaultStatementMappingStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.approved = approved
            self.pinned = pinned
            self.batchSize = batchSize
            self.allergy = allergy
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

        func canMoveTo(_ next: DefaultStatementMappingStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .ready:
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
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == DefaultStatementMappingStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultStatementMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default statement mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netLoad() -> Double {
            return ((floorValue - Double(batchSize)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultStatementMapping {
            return DefaultStatementMapping(
                code: code,
                label: label,
                floorValue: floorValue,
                approved: approved,
                pinned: pinned,
                batchSize: batchSize,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default statement mapping in status idle.
    static func newDefaultStatementMapping(_ code: String, label: String) -> DefaultStatementMapping {
        return DefaultStatementMapping(
            code: code,
            label: label,
            floorValue: 0.0,
            approved: false,
            pinned: false,
            batchSize: 0,
            allergy: "",
            status: DefaultStatementMappingStatus.idle
        )
    }
}
