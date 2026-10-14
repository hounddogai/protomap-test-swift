import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a strict recall entry is in its life cycle.
    enum StrictRecallEntryStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A strict recall entry. Its code is unique within a tenant.
    final class StrictRecallEntry {
        var code: String
        var name: String
        var capacity: Int
        var category: String
        var expiresAt: Int
        var version: Int
        var diagnosisCode: String
        var updatedAt: Int
        var sequence: Int
        var floorValue: Double
        var createdAt: Int
        var status: StrictRecallEntryStatus

        init(code: String, name: String, capacity: Int, category: String, expiresAt: Int, version: Int, diagnosisCode: String, updatedAt: Int, sequence: Int, floorValue: Double, createdAt: Int, status: StrictRecallEntryStatus) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.category = category
            self.expiresAt = expiresAt
            self.version = version
            self.diagnosisCode = diagnosisCode
            self.updatedAt = updatedAt
            self.sequence = sequence
            self.floorValue = floorValue
            self.createdAt = createdAt
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

        func canMoveTo(_ next: StrictRecallEntryStatus) -> Bool {
            switch status {
            case .new:
                return next == StrictRecallEntryStatus.running || next == StrictRecallEntryStatus.failed
            case .queued:
                return next == StrictRecallEntryStatus.done
            case .running:
                return next == StrictRecallEntryStatus.done || next == StrictRecallEntryStatus.failed
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

        func moveTo(_ next: StrictRecallEntryStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("strict recall entry \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return (Double(sequence) * Double(expiresAt) * 100).rounded() / 100
        }

        func copyValue() -> StrictRecallEntry {
            return StrictRecallEntry(
                code: code,
                name: name,
                capacity: capacity,
                category: category,
                expiresAt: expiresAt,
                version: version,
                diagnosisCode: diagnosisCode,
                updatedAt: updatedAt,
                sequence: sequence,
                floorValue: floorValue,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a strict recall entry in status new.
    static func newStrictRecallEntry(_ code: String, name: String) -> StrictRecallEntry {
        return StrictRecallEntry(
            code: code,
            name: name,
            capacity: 0,
            category: "",
            expiresAt: 0,
            version: 0,
            diagnosisCode: "",
            updatedAt: 0,
            sequence: 0,
            floorValue: 0.0,
            createdAt: 0,
            status: StrictRecallEntryStatus.new
        )
    }
}
