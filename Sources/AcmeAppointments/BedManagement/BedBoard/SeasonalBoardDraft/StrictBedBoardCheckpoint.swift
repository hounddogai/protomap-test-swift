import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a strict bed board checkpoint is in its life cycle.
    enum StrictBedBoardCheckpointStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A strict bed board checkpoint as the bed board team keeps it.
    final class StrictBedBoardCheckpoint {
        var code: String
        var name: String
        var cost: Double
        var unit: String
        var currency: String
        var pinned: Bool
        var attributes: [String: String]
        var reviewer: String
        var maximum: Double
        var channel: String
        var status: StrictBedBoardCheckpointStatus

        init(code: String, name: String, cost: Double, unit: String, currency: String, pinned: Bool, attributes: [String: String], reviewer: String, maximum: Double, channel: String, status: StrictBedBoardCheckpointStatus) {
            self.code = code
            self.name = name
            self.cost = cost
            self.unit = unit
            self.currency = currency
            self.pinned = pinned
            self.attributes = attributes
            self.reviewer = reviewer
            self.maximum = maximum
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: StrictBedBoardCheckpointStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .active:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == StrictBedBoardCheckpointStatus.suspended
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: StrictBedBoardCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict bed board checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("strict bed board checkpoint") \(code)"
        }

        func attribute(_ key: String, fallback: String) -> String {
            guard let found = attributes[key] else {
                return fallback
            }
            if found.trimmingCharacters(in: .whitespaces) == "" {
                return fallback
            }
            return found
        }

        func effectiveExposure() -> Double {
            return ((maximum - cost) * 100).rounded() / 100
        }

        func copyValue() -> StrictBedBoardCheckpoint {
            return StrictBedBoardCheckpoint(
                code: code,
                name: name,
                cost: cost,
                unit: unit,
                currency: currency,
                pinned: pinned,
                attributes: attributes,
                reviewer: reviewer,
                maximum: maximum,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a strict bed board checkpoint in status draft.
    static func newStrictBedBoardCheckpoint(_ code: String, name: String) -> StrictBedBoardCheckpoint {
        return StrictBedBoardCheckpoint(
            code: code,
            name: name,
            cost: 0.0,
            unit: "",
            currency: "",
            pinned: false,
            attributes: [:],
            reviewer: "",
            maximum: 0.0,
            channel: "",
            status: StrictBedBoardCheckpointStatus.draft
        )
    }
}
