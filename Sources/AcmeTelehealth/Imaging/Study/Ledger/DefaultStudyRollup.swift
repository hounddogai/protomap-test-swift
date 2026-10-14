import AcmePlatform
import Foundation

extension Imaging {
    /// Where a default study rollup is in its life cycle.
    enum DefaultStudyRollupStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a default study rollup and its current status.
    final class DefaultStudyRollup {
        var code: String
        var label: String
        var createdAt: Int
        var ratio: Double
        var unit: String
        var quantity: Int
        var floorValue: Double
        var attempts: Int
        var status: DefaultStudyRollupStatus

        init(code: String, label: String, createdAt: Int, ratio: Double, unit: String, quantity: Int, floorValue: Double, attempts: Int, status: DefaultStudyRollupStatus) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.ratio = ratio
            self.unit = unit
            self.quantity = quantity
            self.floorValue = floorValue
            self.attempts = attempts
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

        func canMoveTo(_ next: DefaultStudyRollupStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultStudyRollupStatus.inReview
            case .inReview:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == DefaultStudyRollupStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultStudyRollupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default study rollup \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveVolume() -> Double {
            return ((Double(quantity) - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> DefaultStudyRollup {
            return DefaultStudyRollup(
                code: code,
                label: label,
                createdAt: createdAt,
                ratio: ratio,
                unit: unit,
                quantity: quantity,
                floorValue: floorValue,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a default study rollup in status open.
    static func newDefaultStudyRollup(_ code: String, label: String) -> DefaultStudyRollup {
        return DefaultStudyRollup(
            code: code,
            label: label,
            createdAt: 0,
            ratio: 0.0,
            unit: "",
            quantity: 0,
            floorValue: 0.0,
            attempts: 0,
            status: DefaultStudyRollupStatus.`open`
        )
    }
}
