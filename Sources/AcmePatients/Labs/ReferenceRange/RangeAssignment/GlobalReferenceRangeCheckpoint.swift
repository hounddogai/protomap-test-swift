import AcmePlatform
import Foundation

extension Labs {
    /// Where a global reference range checkpoint is in its life cycle.
    enum GlobalReferenceRangeCheckpointStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One global reference range checkpoint, with what the planners need to act on it.
    final class GlobalReferenceRangeCheckpoint {
        var code: String
        var name: String
        var acuity: Int
        var quantity: Int
        var locale: String
        var ratio: Double
        var tags: [String]
        var payer: String
        var batchSize: Int
        var retries: Int
        var weight: Double
        var status: GlobalReferenceRangeCheckpointStatus

        init(code: String, name: String, acuity: Int, quantity: Int, locale: String, ratio: Double, tags: [String], payer: String, batchSize: Int, retries: Int, weight: Double, status: GlobalReferenceRangeCheckpointStatus) {
            self.code = code
            self.name = name
            self.acuity = acuity
            self.quantity = quantity
            self.locale = locale
            self.ratio = ratio
            self.tags = tags
            self.payer = payer
            self.batchSize = batchSize
            self.retries = retries
            self.weight = weight
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalReferenceRangeCheckpointStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == GlobalReferenceRangeCheckpointStatus.inProgress || next == GlobalReferenceRangeCheckpointStatus.completed
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: GlobalReferenceRangeCheckpointStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global reference range checkpoint \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func netVolume() -> Double {
            return ((Double(acuity) - Double(quantity)) * 100).rounded() / 100
        }

        func copyValue() -> GlobalReferenceRangeCheckpoint {
            return GlobalReferenceRangeCheckpoint(
                code: code,
                name: name,
                acuity: acuity,
                quantity: quantity,
                locale: locale,
                ratio: ratio,
                tags: tags,
                payer: payer,
                batchSize: batchSize,
                retries: retries,
                weight: weight,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a global reference range checkpoint in status planned.
    static func newGlobalReferenceRangeCheckpoint(_ code: String, name: String) -> GlobalReferenceRangeCheckpoint {
        return GlobalReferenceRangeCheckpoint(
            code: code,
            name: name,
            acuity: 0,
            quantity: 0,
            locale: "",
            ratio: 0.0,
            tags: [],
            payer: "",
            batchSize: 0,
            retries: 0,
            weight: 0.0,
            status: GlobalReferenceRangeCheckpointStatus.planned
        )
    }
}
