import AcmePlatform
import Foundation

extension Imaging {
    /// Where a read mapping is in its life cycle.
    enum ReadMappingStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a read mapping and its current status.
    final class ReadMapping {
        var code: String
        var name: String
        var createdAt: Int
        var allergy: String
        var limit: Int
        var dosageMg: Double
        var specialty: String
        var batchSize: Int
        var floorValue: Double
        var region: String
        var status: ReadMappingStatus

        init(code: String, name: String, createdAt: Int, allergy: String, limit: Int, dosageMg: Double, specialty: String, batchSize: Int, floorValue: Double, region: String, status: ReadMappingStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.allergy = allergy
            self.limit = limit
            self.dosageMg = dosageMg
            self.specialty = specialty
            self.batchSize = batchSize
            self.floorValue = floorValue
            self.region = region
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

        func canMoveTo(_ next: ReadMappingStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == ReadMappingStatus.cancelled
            case .inProgress:
                return next == ReadMappingStatus.completed
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

        func moveTo(_ next: ReadMappingStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("read mapping \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func netValue() -> Double {
            return (Double(limit) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> ReadMapping {
            return ReadMapping(
                code: code,
                name: name,
                createdAt: createdAt,
                allergy: allergy,
                limit: limit,
                dosageMg: dosageMg,
                specialty: specialty,
                batchSize: batchSize,
                floorValue: floorValue,
                region: region,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a read mapping in status planned.
    static func newReadMapping(_ code: String, name: String) -> ReadMapping {
        return ReadMapping(
            code: code,
            name: name,
            createdAt: 0,
            allergy: "",
            limit: 0,
            dosageMg: 0.0,
            specialty: "",
            batchSize: 0,
            floorValue: 0.0,
            region: "",
            status: ReadMappingStatus.planned
        )
    }
}
