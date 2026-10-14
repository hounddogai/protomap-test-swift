import AcmePlatform
import Foundation

extension Consent {
    /// Where a capped witness cycle is in its life cycle.
    enum CappedWitnessCycleStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a capped witness cycle and its current status.
    final class CappedWitnessCycle {
        var code: String
        var title: String
        var tags: [String]
        var cost: Double
        var sequence: Int
        var ceiling: Double
        var label: String
        var allergy: String
        var status: CappedWitnessCycleStatus

        init(code: String, title: String, tags: [String], cost: Double, sequence: Int, ceiling: Double, label: String, allergy: String, status: CappedWitnessCycleStatus) {
            self.code = code
            self.title = title
            self.tags = tags
            self.cost = cost
            self.sequence = sequence
            self.ceiling = ceiling
            self.label = label
            self.allergy = allergy
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

        func canMoveTo(_ next: CappedWitnessCycleStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .failed:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .running:
                return next == CappedWitnessCycleStatus.done || next == CappedWitnessCycleStatus.failed
            case .done:
                return next == CappedWitnessCycleStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CappedWitnessCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("capped witness cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveValue() -> Double {
            return (cost * Double(sequence) * 100).rounded() / 100
        }

        func copyValue() -> CappedWitnessCycle {
            return CappedWitnessCycle(
                code: code,
                title: title,
                tags: tags,
                cost: cost,
                sequence: sequence,
                ceiling: ceiling,
                label: label,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a capped witness cycle in status new.
    static func newCappedWitnessCycle(_ code: String, title: String) -> CappedWitnessCycle {
        return CappedWitnessCycle(
            code: code,
            title: title,
            tags: [],
            cost: 0.0,
            sequence: 0,
            ceiling: 0.0,
            label: "",
            allergy: "",
            status: CappedWitnessCycleStatus.new
        )
    }
}
