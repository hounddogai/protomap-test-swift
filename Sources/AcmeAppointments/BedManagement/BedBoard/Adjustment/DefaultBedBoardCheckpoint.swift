import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a default bed board checkpoint is in its life cycle.
    enum DefaultBedBoardCheckpointStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// One default bed board checkpoint, with what the planners need to act on it.
    final class DefaultBedBoardCheckpoint {
        var code: String
        var name: String
        var title: String
        var description: String
        var externalRef: String
        var payer: String
        var quantity: Int
        var reviewer: String
        var budget: Double
        var label: String
        var status: DefaultBedBoardCheckpointStatus

        init(code: String, name: String, title: String, description: String, externalRef: String, payer: String, quantity: Int, reviewer: String, budget: Double, label: String, status: DefaultBedBoardCheckpointStatus) {
            self.code = code
            self.name = name
            self.title = title
            self.description = description
            self.externalRef = externalRef
            self.payer = payer
            self.quantity = quantity
            self.reviewer = reviewer
            self.budget = budget
            self.label = label
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

        func canMoveTo(_ next: DefaultBedBoardCheckpointStatus) -> Bool {
            switch status {
            case .new:
                return next == DefaultBedBoardCheckpointStatus.done
            case .queued:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == DefaultBedBoardCheckpointStatus.done
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

        func moveTo(_ next: DefaultBedBoardCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default bed board checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(name))"
        }

        func adjustedValue() -> Double {
            return ((Double(quantity) - budget) * 100).rounded() / 100
        }

        func copyValue() -> DefaultBedBoardCheckpoint {
            return DefaultBedBoardCheckpoint(
                code: code,
                name: name,
                title: title,
                description: description,
                externalRef: externalRef,
                payer: payer,
                quantity: quantity,
                reviewer: reviewer,
                budget: budget,
                label: label,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a default bed board checkpoint in status new.
    static func newDefaultBedBoardCheckpoint(_ code: String, name: String) -> DefaultBedBoardCheckpoint {
        return DefaultBedBoardCheckpoint(
            code: code,
            name: name,
            title: "",
            description: "",
            externalRef: "",
            payer: "",
            quantity: 0,
            reviewer: "",
            budget: 0.0,
            label: "",
            status: DefaultBedBoardCheckpointStatus.new
        )
    }
}
