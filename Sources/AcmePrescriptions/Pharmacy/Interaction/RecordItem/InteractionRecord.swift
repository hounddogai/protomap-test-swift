import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a interaction record is in its life cycle.
    enum InteractionRecordStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a interaction record and its current status.
    final class InteractionRecord {
        var code: String
        var name: String
        var archived: Bool
        var rate: Double
        var updatedAt: Int
        var currency: String
        var score: Double
        var status: InteractionRecordStatus

        init(code: String, name: String, archived: Bool, rate: Double, updatedAt: Int, currency: String, score: Double, status: InteractionRecordStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.rate = rate
            self.updatedAt = updatedAt
            self.currency = currency
            self.score = score
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

        func canMoveTo(_ next: InteractionRecordStatus) -> Bool {
            switch status {
            case .new:
                return next == InteractionRecordStatus.queued
            case .queued:
                return next == InteractionRecordStatus.running
            case .running:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: InteractionRecordStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("interaction record \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return ((score - rate) * 100).rounded() / 100
        }

        func copyValue() -> InteractionRecord {
            return InteractionRecord(
                code: code,
                name: name,
                archived: archived,
                rate: rate,
                updatedAt: updatedAt,
                currency: currency,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a interaction record in status new.
    static func newInteractionRecord(_ code: String, name: String) -> InteractionRecord {
        return InteractionRecord(
            code: code,
            name: name,
            archived: false,
            rate: 0.0,
            updatedAt: 0,
            currency: "",
            score: 0.0,
            status: InteractionRecordStatus.new
        )
    }
}
