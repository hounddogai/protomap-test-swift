import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a rolling program batch is in its life cycle.
    enum RollingProgramBatchStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a rolling program batch and its current status.
    final class RollingProgramBatch {
        var code: String
        var name: String
        var archived: Bool
        var weight: Double
        var batchSize: Int
        var procedureCode: String
        var floorValue: Double
        var title: String
        var rate: Double
        var status: RollingProgramBatchStatus

        init(code: String, name: String, archived: Bool, weight: Double, batchSize: Int, procedureCode: String, floorValue: Double, title: String, rate: Double, status: RollingProgramBatchStatus) {
            self.code = code
            self.name = name
            self.archived = archived
            self.weight = weight
            self.batchSize = batchSize
            self.procedureCode = procedureCode
            self.floorValue = floorValue
            self.title = title
            self.rate = rate
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingProgramBatchStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: RollingProgramBatchStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling program batch \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedVolume() -> Double {
            return ((rate - weight) * 100).rounded() / 100
        }

        func copyValue() -> RollingProgramBatch {
            return RollingProgramBatch(
                code: code,
                name: name,
                archived: archived,
                weight: weight,
                batchSize: batchSize,
                procedureCode: procedureCode,
                floorValue: floorValue,
                title: title,
                rate: rate,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a rolling program batch in status requested.
    static func newRollingProgramBatch(_ code: String, name: String) -> RollingProgramBatch {
        return RollingProgramBatch(
            code: code,
            name: name,
            archived: false,
            weight: 0.0,
            batchSize: 0,
            procedureCode: "",
            floorValue: 0.0,
            title: "",
            rate: 0.0,
            status: RollingProgramBatchStatus.requested
        )
    }
}
