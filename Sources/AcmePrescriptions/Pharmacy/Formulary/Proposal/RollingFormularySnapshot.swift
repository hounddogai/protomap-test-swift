import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a rolling formulary snapshot is in its life cycle.
    enum RollingFormularySnapshotStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// The record of a rolling formulary snapshot and its current status.
    final class RollingFormularySnapshot {
        var code: String
        var name: String
        var batchSize: Int
        var createdAt: Int
        var region: String
        var score: Double
        var ceiling: Double
        var currency: String
        var status: RollingFormularySnapshotStatus

        init(code: String, name: String, batchSize: Int, createdAt: Int, region: String, score: Double, ceiling: Double, currency: String, status: RollingFormularySnapshotStatus) {
            self.code = code
            self.name = name
            self.batchSize = batchSize
            self.createdAt = createdAt
            self.region = region
            self.score = score
            self.ceiling = ceiling
            self.currency = currency
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

        func canMoveTo(_ next: RollingFormularySnapshotStatus) -> Bool {
            switch status {
            case .new:
                return next == RollingFormularySnapshotStatus.done
            case .queued:
                switch next {
                case .running:
                    return true
                default:
                    break
                }
                return false
            case .running:
                switch next {
                case .done, .failed:
                    return true
                default:
                    break
                }
                return false
            case .done:
                return next == RollingFormularySnapshotStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingFormularySnapshotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling formulary snapshot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(name)"
        }

        func adjustedTotal() -> Double {
            return (ceiling * Double(batchSize) * 100).rounded() / 100
        }

        func copyValue() -> RollingFormularySnapshot {
            return RollingFormularySnapshot(
                code: code,
                name: name,
                batchSize: batchSize,
                createdAt: createdAt,
                region: region,
                score: score,
                ceiling: ceiling,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a rolling formulary snapshot in status new.
    static func newRollingFormularySnapshot(_ code: String, name: String) -> RollingFormularySnapshot {
        return RollingFormularySnapshot(
            code: code,
            name: name,
            batchSize: 0,
            createdAt: 0,
            region: "",
            score: 0.0,
            ceiling: 0.0,
            currency: "",
            status: RollingFormularySnapshotStatus.new
        )
    }
}
